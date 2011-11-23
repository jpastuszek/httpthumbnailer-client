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
			thumbnail 'crop', 6, 3, 'JPEG' 
			thumbnail 'crop', 8, 8, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end

		thumbs[0].mime_type.should == 'image/jpeg'
		t, s = identify(thumbs[0].data)
		t.should == 'JPEG'
		s.should == '6x3'

		thumbs[1].mime_type.should == 'image/png'
		t, s = identify(thumbs[1].data)
		t.should == 'PNG'
		s.should == '8x8'

		thumbs[2].mime_type.should == 'image/png'
		t, s = identify(thumbs[2].data)
		t.should == 'PNG'
		s.should == '4x4'
	end
end

