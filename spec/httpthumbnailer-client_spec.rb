require_relative 'spec_helper'

describe HTTPThumbnailerClient do
	it 'should provide service URL that is set up to use' do
		HTTPThumbnailerClient.new('http://123.213.213.231').server_url.should == 'http://123.213.213.231'
		HTTPThumbnailerClient.new('http://123.213.213.1').server_url.should == 'http://123.213.213.1'
	end

	it 'should provide keep alive setting' do
		HTTPThumbnailerClient.new('http://123.213.213.231').keep_alive.should be_false
		HTTPThumbnailerClient.new('http://123.213.213.231', keep_alive: true).keep_alive.should be_true
	end

	it 'should provide nice inspect string' do
		HTTPThumbnailerClient.new('http://123.213.213.231', keep_alive: true).inspect.should == '#<HTTPThumbnailerClient server_url="http://123.213.213.231" keep_alive=true>'
	end
end

