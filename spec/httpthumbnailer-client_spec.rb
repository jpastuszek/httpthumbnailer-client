require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'httpthumbnailer-client'

describe HTTPThumbnailerClient::URIBuilder do
	it "should allow building request for thumbnail set" do
		HTTPThumbnailerClient::URIBuilder.thumbnail do
			thumbnail 'crop', 16, 16, 'JPEG' 
			thumbnail 'pad', 32, 64, 'PNG', :magick => 'xdfa', :number => 2
		end.should == '/thumbnail/crop,16,16,JPEG/pad,32,64,PNG,magick:xdfa,number:2'
	end
end

describe HTTPThumbnailerClient do
	before :all do
		server_start
		@data = File.read(spec_dir + 'test.jpg')
	end

	after :all do
		server_stop
	end

	it "should return set of thumbnails matching specified specification" do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail(@data) do
			thumbnail 'crop', 16, 16, 'JPEG' 
			thumbnail 'crop', 32, 64, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end
		p thumbs
	end
end

