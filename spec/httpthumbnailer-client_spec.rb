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
		@data = (spec_dir + 'test.jpg').read
	end

	after :all do
		server_stop
	end

	it "should return set of thumbnails matching specified specification" do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail(@data) do
			thumbnail 'crop', 6, 3, 'JPEG' 
			thumbnail 'crop', 8, 8, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end

		thumbs[0].mime_type.should == 'image/jpeg'
		i = identify(thumbs[0].data)
		i.format.should == 'JPEG'
		i.width.should == 6
		i.height.should == 3

		thumbs[1].mime_type.should == 'image/png'
		i = identify(thumbs[1].data)
		i.format.should == 'PNG'
		i.width.should == 8
		i.height.should == 8

		thumbs[2].mime_type.should == 'image/png'
		i = identify(thumbs[2].data)
		i.format.should == 'PNG'
		i.width.should == 4
		i.height.should == 4
	end

	it "should raise HTTPThumbnailerClient::UnsupportedMediaTypeError error on unsupported media type" do
		lambda {
			HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.txt').read) do
				thumbnail 'crop', 6, 3, 'JPEG' 
				thumbnail 'crop', 8, 8, 'PNG'
			end
		}.should raise_error HTTPThumbnailerClient::UnsupportedMediaTypeError
	end
end

