require_relative 'spec_helper'

describe HTTPThumbnailerClient::URIParser do
	describe 'parsing options' do
		context 'for valid input string' do
			it 'should provide hash map' do
				map = subject.class.parse_options('hello:world,this:is:a:test,abc:123')
				map.should include('hello' => 'world')
				map.should include('this' => 'is:a:test')
				map.should include('abc' => '123')
			end
		end
		context 'with invalid input' do
			it 'should raise ArgumentError on empty key name' do
				expect {
					subject.class.parse_options(':world,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key name for value 'world'"
				expect {
					subject.class.parse_options('hello:world,:test,abc:123')
				}.to raise_error ArgumentError, "missing option key name for value 'test'"
			end

			it 'should raise ArgumentError on empty key-value pair' do
				expect {
					subject.class.parse_options(',this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing key-value pair on position 1"
				expect {
					subject.class.parse_options('hello:world,,abc:123')
				}.to raise_error ArgumentError, "missing key-value pair on position 2"
			end

			it 'should raise ArgumentError on empty key value' do
				expect {
					subject.class.parse_options('hello:,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'hello'"
				expect {
					subject.class.parse_options('hello:world,this:,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'this'"
			end

			it 'should raise ArgumentError on missing key-value separator' do
				expect {
					subject.class.parse_options('hello,this:is:a:test,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'hello'"
				expect {
					subject.class.parse_options('hello:world,this,abc:123')
				}.to raise_error ArgumentError, "missing option key value for key 'this'"
			end
		end
	end
end

