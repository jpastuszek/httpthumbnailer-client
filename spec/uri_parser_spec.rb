require_relative 'spec_helper'

describe HTTPThumbnailerClient::ThumbnailingSpec do
	subject do
		HTTPThumbnailerClient::ThumbnailingSpec
	end

	describe HTTPThumbnailerClient::ThumbnailingSpec::EditSpec do
		subject do
			HTTPThumbnailerClient::ThumbnailingSpec::EditSpec
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
			context 'with invalid input' do
				it 'should rain ArgumentError on empty argument list' do
					expect {
						subject.from_string('')
					}.to raise_error ArgumentError, 'missing name argument'
				end

				it 'should rain ArgumentError on empty name' do
					expect {
						subject.from_string(',1,2,3,4')
					}.to raise_error ArgumentError, 'missing name argument'
				end

				context 'options' do
					it 'should raise same ArgumentError as for #parse_options but with edit name' do
						expect {
							subject.from_string('crop,:world,this:is:a:test,abc:123')
						}.to raise_error ArgumentError, "missing option key name for value 'world' for edit 'crop'"
						expect {
							subject.from_string('rotate,30,blah:')
						}.to raise_error ArgumentError, "missing option key value for key 'blah' for edit 'rotate'"
					end
				end
			end
		end
	end

	describe '#parse_options' do
		context 'for valid input string' do
			it 'should provide hash map' do
				options = subject.parse_options('hello:world,this:is:a:test,abc:123')
				options.should == {'hello' => 'world', 'this' => 'is:a:test', 'abc' => '123'}
			end
		end
		context 'with invalid input' do
			it 'should raise ArgumentError on empty key name' do
				expect {
					subject.parse_options(':world,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key name for value 'world'"
				expect {
					subject.parse_options('hello:world,:test,abc:123')
				}.to raise_error ArgumentError, "missing option key name for value 'test'"
			end

			it 'should raise ArgumentError on empty key-value pair' do
				expect {
					subject.parse_options(',this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing key-value pair on position 1"
				expect {
					subject.parse_options('hello:world,,abc:123')
				}.to raise_error ArgumentError, "missing key-value pair on position 2"
			end

			it 'should raise ArgumentError on empty key value' do
				expect {
					subject.parse_options('hello:,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'hello'"
				expect {
					subject.parse_options('hello:world,this:,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'this'"
			end

			it 'should raise ArgumentError on missing key-value separator' do
				expect {
					subject.parse_options('hello,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'hello'"
				expect {
					subject.parse_options('hello:world,this,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'this'"
			end
		end
	end

	describe '#from_string' do
		context 'for valid input string' do
			context 'with just thumbnailing spec' do
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
			context 'with thumbnailing spec containing options' do
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
			context 'with thumbnailing spec containing edits' do
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
	end
end

