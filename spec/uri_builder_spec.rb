require_relative 'spec_helper'

describe HTTPThumbnailerClient::URIBuilder do
	describe 'building single thumbnail URL' do
		context 'with thumbnail method and args' do
			it 'should build URL with given method and args' do
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png')
				.should == '/thumbnail/pad,32,64,png'
			end

			context 'and options' do
				it 'should build URL with given options' do
					HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {'background-color' => 'black'})
					.should == '/thumbnail/pad,32,64,png,background-color:black'
				end

				context 'with options provided in symbol to primitive form' do
					it 'should build URL with given options converted to proper from' do
						HTTPThumbnailerClient::URIBuilder.thumbnail('crop', 32, 64, 'png', {background_color: 'black', float_x: 1.0})
						.should == '/thumbnail/crop,32,64,png,background-color:black,float-x:1.0'
					end
				end
			end
		end

		context 'with edits' do
			it 'should add edits to the URL' do
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
					edit('crop', 0.1, 0.1, 0.8, 0.8)
					edit('blur', 0.5, 0.5, 0.1, 0.1)
				end
				.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!blur,0.5,0.5,0.1,0.1'
			end

			context 'with edit options' do
				it 'should build URL with given options' do
					HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
						edit('crop', 0.1, 0.1, 0.8, 0.8)
						edit('blur', 0.5, 0.5, 0.1, 0.1, {'sigma' => 31})
					end
					.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!blur,0.5,0.5,0.1,0.1,sigma:31'
				end

				context 'with options provided in symbol to primitive form' do
					it 'should build URL with given options converted to proper from' do
						HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
							edit('crop', 0.1, 0.1, 0.8, 0.8)
							edit('rotate', 90, {background_color: 'red', test: 42})
						end
						.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!rotate,90,background-color:red,test:42'
					end
				end
			end
		end

		describe 'available builder methods' do
			subject do
				inner_context = nil
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
					inner_context = self
				end
				inner_context
			end
			it 'should respond to .edits only' do
				subject.should respond_to :edit
				subject.should respond_to :edit_spec
				subject.should_not respond_to :thumbnail
				subject.should_not respond_to :thumbnail_spec
			end
		end
	end

	describe 'multipart thumbanils URI' do
		it 'should allow building request for thumbnail set' do
			HTTPThumbnailerClient::URIBuilder.thumbnails do
				thumbnail 'crop', 16, 16, 'jpeg'
				thumbnail 'pad', 32, 64, 'png', {magick: 'xdfa', number: 2}
			end.should == '/thumbnails/crop,16,16,jpeg/pad,32,64,png,magick:xdfa,number:2'
		end

		it 'should allow building request for thumbnail set with edits' do
			HTTPThumbnailerClient::URIBuilder.thumbnails do
				thumbnail('crop', 16, 16, 'jpeg') do
					edit('test', '1', '2')
					edit('test2', {'b' => 2, 'a' => 1})
				end

				thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2})

				thumbnail('fit', 16, 16, 'jpeg', {magick: 'xdfa', number: 3}) do
					edit('test', '1', '2', {'b' => 2, 'a' => 1})
				end
			end.should == '/thumbnails/crop,16,16,jpeg!test,1,2!test2,a:1,b:2/pad,32,64,png,magick:xdfa,number:2/fit,16,16,jpeg,magick:xdfa,number:3!test,1,2,a:1,b:2'
		end

		describe 'available builder methods' do
			subject do
				inner_context = nil
				HTTPThumbnailerClient::URIBuilder.thumbnails do
					inner_context = self
				end
				inner_context
			end
			it 'should respond to #thumbnail and #thumbnail_spec only' do
				subject.should_not respond_to :edit
				subject.should_not respond_to :edit_spec
				subject.should respond_to :thumbnail
				subject.should respond_to :thumbnail_spec
			end
		end
	end

	describe 'error handling' do
		it 'should raise ThumbnailingSpec::MissingOptionKeyValueError on bad thumbaniling options' do
			expect {
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: nil, number: 2})
			}.to raise_error HTTPThumbnailerClient::ThumbnailingSpec::MissingOptionKeyValueError, "missing option value for key 'magick'"
		end

		it 'should raise ThumbnailingSpec::MissingOptionKeyValueError on bad edit options' do
			expect {
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'blah', number: 2}) do
					edit 'test', {hello: nil}
				end
			}.to raise_error HTTPThumbnailerClient::ThumbnailingSpec::MissingOptionKeyValueError, "missing option value for key 'hello' for edit 'test'"
		end
	end

	describe 'building from provided specs' do
		let :edit1 do
			HTTPThumbnailerClient::ThumbnailingSpec::EditSpec.new('rotate', ['30'], 'background-color' => 'red', 'blah' => 'xyz')
		end

		let :edit2 do
			HTTPThumbnailerClient::ThumbnailingSpec::EditSpec.new('crop', ['1', '2', '3', '4'])
		end

		let :spec1 do
			edits = []
			edits << edit1
			edits << edit2
			HTTPThumbnailerClient::ThumbnailingSpec.new('crop', '100', '200', 'PNG', {'abc' => 'xyz', 'a' => 'b'}, edits)
		end

		let :spec2 do
			HTTPThumbnailerClient::ThumbnailingSpec.new('pad', '100', '200', 'PNG')
		end

		describe '#specs' do
			context 'when provided single ThumbnailingSpec object' do
				it 'should build URI for single thumbnail API with that spec' do
					HTTPThumbnailerClient::URIBuilder.specs(spec1).should == '/thumbnail/crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4'
				end
			end

			context 'when provided multiple ThumbnailingSpec object' do
				it 'should build URI for multiple thumbnail API with that specs' do
					HTTPThumbnailerClient::URIBuilder.specs(spec1, spec2).should == '/thumbnails/crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4/pad,100,200,PNG'
				end
			end
		end

		describe 'building single thumbnail URL' do
			describe '#edit_spec' do
				it 'should allow passing EditSpec object' do
					e1 = edit1
					e2 = edit2

					HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
						edit_spec(e1)
						edit_spec(e2)
					end
					.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4'
				end
			end
		end

		describe 'multipart thumbanils URI' do
			describe '#thumbnail_spec' do
				it 'should allow passing ThumbnailingSpec object' do
					s1 = spec1
					s2 = spec2

					HTTPThumbnailerClient::URIBuilder.thumbnails do
						thumbnail_spec(s1)
						thumbnail_spec(s2)
					end
					.should == '/thumbnails/crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4/pad,100,200,PNG'
				end
			end
		end

		describe 'directly on builder object' do
			context 'with #thumbnail_spec' do
				it 'should build URI for single thumbnail API with single spec' do
					builder = HTTPThumbnailerClient::URIBuilder.new
					builder.thumbnail_spec(spec1)
					builder.to_s.should == '/thumbnail/crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4'
				end

				it 'should build URI for multiple thumbnail API with that specs' do
					builder = HTTPThumbnailerClient::URIBuilder.new
					builder.thumbnail_spec(spec1)
					builder.thumbnail_spec(spec2)
					builder.to_s.should == '/thumbnails/crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4/pad,100,200,PNG'
				end
			end

			context 'with #thumbnail builder' do
				it 'should build URI for single thumbnail API with single spec' do
					builder = HTTPThumbnailerClient::URIBuilder.new
					builder.thumbnail('crop', 16, 16, 'jpeg') do
						edit('test', '1', '2')
						edit('test2', {'b' => 2, 'a' => 1})
					end
					builder.to_s.should == '/thumbnail/crop,16,16,jpeg!test,1,2!test2,a:1,b:2'
				end

				it 'should build URI for multiple thumbnail API with that specs' do
					builder = HTTPThumbnailerClient::URIBuilder.new
					builder.thumbnail('crop', 16, 16, 'jpeg') do
						edit('test', '1', '2')
						edit('test2', {'b' => 2, 'a' => 1})
					end
					builder.thumbnail('pad', 10, 10, 'PNG')
					builder.to_s.should == '/thumbnails/crop,16,16,jpeg!test,1,2!test2,a:1,b:2/pad,10,10,PNG'
				end
			end
		end
	end
end

