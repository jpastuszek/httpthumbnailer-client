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
				HTTPThumbnailerClient::URIBuilder
					.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
						edit('crop', 0.1, 0.1, 0.8, 0.8)
						edit('blur', 0.5, 0.5, 0.1, 0.1)
					end
				.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!blur,0.5,0.5,0.1,0.1'
			end

			context 'with edit options' do
				it 'should build URL with given options' do
					HTTPThumbnailerClient::URIBuilder
						.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
							edit('crop', 0.1, 0.1, 0.8, 0.8)
							edit('blur', 0.5, 0.5, 0.1, 0.1, {'sigma' => 31})
						end
					.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!blur,0.5,0.5,0.1,0.1,sigma:31'
				end

				context 'with options provided in symbol to primitive form' do
					it 'should build URL with given options converted to proper from' do
						HTTPThumbnailerClient::URIBuilder
							.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2}) do
								edit('crop', 0.1, 0.1, 0.8, 0.8)
								edit('rotate', 90, {background_color: 'red', test: 42})
							end
						.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2!crop,0.1,0.1,0.8,0.8!rotate,90,background-color:red,test:42'
					end
				end
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
	end

	describe 'error handling' do
		it 'should raise InvalidThumbnailSpecificationError on bad thumbaniling options' do
			expect {
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: nil, number: 2})
			}.to raise_error HTTPThumbnailerClient::InvalidThumbnailSpecificationError, "missing option value for key 'magick'"
		end

		it 'should raise InvalidThumbnailSpecificationError on bad edit options' do
			expect {
				HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'blah', number: 2}) do
					edit 'test', {hello: nil}
				end
			}.to raise_error HTTPThumbnailerClient::InvalidThumbnailSpecificationError, "missing option value for key 'hello' for edit 'test'"
		end
	end
end

