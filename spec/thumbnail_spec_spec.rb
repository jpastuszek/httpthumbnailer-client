require_relative 'spec_helper'
require 'httpthumbnailer-client/thumbnail_spec'

describe HTTPThumbnailerClient::ThumbnailSpec do
	subject do
		HTTPThumbnailerClient::ThumbnailSpec
	end

	describe HTTPThumbnailerClient::ThumbnailSpec::Builder do
		subject do
			HTTPThumbnailerClient::ThumbnailSpec::Builder
		end

		it 'should allow building basic specification' do
			builder = subject.new('crop', 16, 16, 'jpeg')
			builder.spec.should be_a HTTPThumbnailerClient::ThumbnailSpec
			builder.spec.to_s.should == 'crop,16,16,jpeg'
		end

		describe 'adding edits' do
			context 'with block' do
				it 'should allow building specification with edits' do
					builder = subject.new('crop', 16, 16, 'jpeg') do
						edit('test', '1', '2')
						edit('test2', {'b' => 2, 'a' => 1})
					end

					builder.spec.should be_a HTTPThumbnailerClient::ThumbnailSpec
					builder.spec.to_s.should == 'crop,16,16,jpeg!test,1,2!test2,a:1,b:2'
				end
			end
			context 'with #edit' do
				it 'should allow building specification with edits' do
					builder = subject.new('crop', 16, 16, 'jpeg') do
						edit('test', '1', '2')
						edit('test2', {'b' => 2, 'a' => 1})
					end
					builder.edit('test3')

					builder.spec.should be_a HTTPThumbnailerClient::ThumbnailSpec
					builder.spec.to_s.should == 'crop,16,16,jpeg!test,1,2!test2,a:1,b:2!test3'
				end
			end
			context 'with #edit_spec' do
				it 'should allow building specification with edits' do
					builder = subject.new('crop', 16, 16, 'jpeg') do
						edit_spec  HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('rotate', ['30'], 'background-color' => 'red', 'blah' => 'xyz')
					end
					builder.edit_spec HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('crop', ['1', '2', '3', '4'])

					builder.spec.should be_a HTTPThumbnailerClient::ThumbnailSpec
					builder.spec.to_s.should == 'crop,16,16,jpeg!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4'
				end
			end
		end
	end

	describe HTTPThumbnailerClient::ThumbnailSpec::EditSpec do
		subject do
			HTTPThumbnailerClient::ThumbnailSpec::EditSpec
		end

		describe '#from_string' do
			context 'for valid input string' do
				it 'should provide edits spec object' do
					edit = subject.from_string('crop,1,2,3,4')
					edit.name.should == 'crop'
					edit.args.should have(4).arguments
					edit.args.should == ['1', '2', '3', '4']
				end
				context 'with options' do
					it 'should provide edits spec object with parsed options' do
						edit = subject.from_string('crop,1,2,3,4,hello:world,this:is:a:test,abc:123')
						edit.name.should == 'crop'
						edit.args.should have(4).arguments
						edit.args.should == ['1', '2', '3', '4']
						edit.options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
					end
				end
				context 'with only options' do
					it 'should provide edits spec object with parsed options' do
						edit = subject.from_string('magick,hello:world,this:is:a:test,abc:123')
						edit.name.should == 'magick'
						edit.args.should have(0).arguments
						edit.args.should be_empty
						edit.options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
					end
				end
			end
			context 'for invalid input' do
				it 'should rain MissingArgumentError on empty argument list' do
					expect {
						subject.from_string('')
					}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingArgumentError, 'missing edit name argument'
				end

				it 'should rain MissingArgumentError on empty name' do
					expect {
						subject.from_string(',1,2,3,4')
					}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingArgumentError, 'missing edit name argument'
				end

				context 'options' do
					it 'should raise same MissingOptionKeyValueError as for #parse_options but with edit name' do
						expect {
							subject.from_string('crop,:world,this:is:a:test,abc:123')
						}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyNameError, "missing option key name for value 'world' for edit 'crop'"
						expect {
							subject.from_string('rotate,30,blah:')
						}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'blah' for edit 'rotate'"
					end
				end
			end
		end

		describe '#to_s' do
			subject do
				HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('rotate', '30', 'background-color' => 'red', 'blah' => 'xyz')
			end

			it 'should construct string from spec' do
				subject.to_s.should == 'rotate,30,background-color:red,blah:xyz'
			end

			context 'with nil options values' do
				it 'should raise MissingOptionKeyValueError for edit' do
					expect {
						HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('rotate', '30', 'background-color' => 'red', 'blah' => nil).to_s
					}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'blah' for edit 'rotate'"
				end
			end
		end
	end

	describe '#parse_options' do
		context 'for valid input array of option strings' do
			it 'should provide hash map' do
				options = subject.parse_options(['hello:world', 'this:is:a:test', 'abc:123'])
				options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
			end
		end
		context 'for invalid input' do
			it 'should raise MissingOptionKeyNameError on empty key name' do
				expect {
					subject.parse_options([':world', 'this:is:a:test', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyNameError, "missing option key name for value 'world'"
				expect {
					subject.parse_options(['hello:world', ':test', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyNameError, "missing option key name for value 'test'"
			end

			it 'should raise MissingOptionKeyValuePairError on empty key-value pair' do
				expect {
					subject.parse_options(['', 'this:is:a:test', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValuePairError, "missing key-value pair on position 1"
				expect {
					subject.parse_options(['hello:world', '', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValuePairError, "missing key-value pair on position 2"
			end

			it 'should raise MissingOptionKeyValueError on empty value' do
				expect {
					subject.parse_options(['hello:', 'this:is:a:test', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'hello'"
				expect {
					subject.parse_options(['hello:world', 'this:', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'this'"
			end

			it 'should raise MissingOptionKeyValueError on missing key-value separator' do
				expect {
					subject.parse_options(['hello', 'this:is:a:test', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'hello'"
				expect {
					subject.parse_options(['hello:world', 'this', 'abc:123'])
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'this'"
			end
		end
	end

	describe '#from_string' do
		context 'for valid input string' do
			context 'with just thumbnail spec' do
				it 'should provide spec object' do
					spec = subject.from_string('pad,123,input,JPEG')
					spec.method.should == 'pad'
					spec.width.should == '123'
					spec.height.should == 'input'
					spec.format.should == 'JPEG'
					spec.options.should == {}
					spec.edits.should == []
				end
			end
			context 'with thumbnail spec containing options' do
				it 'should provide spec object with parsed options' do
					spec = subject.from_string('pad,123,input,JPEG,hello:world,this:is:a:test,abc:123')
					spec.method.should == 'pad'
					spec.width.should == '123'
					spec.height.should == 'input'
					spec.format.should == 'JPEG'
					spec.options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
					spec.edits.should == []
				end
			end
			context 'with thumbnail spec containing edits' do
				it 'should provide spec object with parsed edits' do
					spec = subject.from_string('pad,123,input,JPEG,hello:world,this:is:a:test,abc:123!crop,1,2,3,4!rotate,30')
					spec.method.should == 'pad'
					spec.width.should == '123'
					spec.height.should == 'input'
					spec.format.should == 'JPEG'
					spec.options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
					spec.edits.should have(2).edits
					spec.edits[0].name.should == 'crop'
					spec.edits[0].args.should have(4).arguments
					spec.edits[0].args.should == ['1', '2', '3', '4']
					spec.edits[1].name.should == 'rotate'
					spec.edits[1].args.should have(1).argument
					spec.edits[1].args.should == ['30']
				end
			end
		end
		context 'for invalid input' do
			context 'with missing arguments' do
				it 'should raise MissingArgumentError' do
					expect {
						subject.from_string('pad,123,input,hello:world,this:is:a:test,abc:123')
					}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingArgumentError, "missing format argument in spec 'pad,123,input,hello:world,this:is:a:test,abc:123'"
				end
			end
		end
	end

	describe '#options_to_s' do
		it 'should format option string from hash with sorting of key' do
			HTTPThumbnailerClient::ThumbnailSpec.options_to_s('xyz' => 'abc', 'abc' => '123', '123' => 'aaa').should == ['123:aaa', 'abc:123', 'xyz:abc']
		end

		it 'should convert symbol keys to strings' do
			HTTPThumbnailerClient::ThumbnailSpec.options_to_s(background_color: 'red').should == ['background-color:red']
		end

		context 'with nil keys' do
			it 'should raise MissingOptionKeyNameError' do
				expect {
					HTTPThumbnailerClient::ThumbnailSpec.options_to_s(nil => 'red')
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyNameError, "missing option key name for value 'red'"
			end
		end

		context 'with nil values' do
			it 'should raise MissingOptionKeyValueError' do
				expect {
					HTTPThumbnailerClient::ThumbnailSpec.options_to_s('blah' => nil)
				}.to raise_error HTTPThumbnailerClient::ThumbnailSpec::MissingOptionKeyValueError, "missing option value for key 'blah'"
			end
		end
	end

	describe '#to_s' do
		subject do
			edits = []
			edits << HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('rotate', ['30'], 'background-color' => 'red', 'blah' => 'xyz')
			edits << HTTPThumbnailerClient::ThumbnailSpec::EditSpec.new('crop', ['1', '2', '3', '4'])

			HTTPThumbnailerClient::ThumbnailSpec.new('crop', '100', '200', 'PNG', {'abc' => 'xyz', 'a' => 'b'}, edits)
		end

		it 'should construct string from spec' do
			subject.to_s.should == 'crop,100,200,PNG,a:b,abc:xyz!rotate,30,background-color:red,blah:xyz!crop,1,2,3,4'
		end
	end
end

