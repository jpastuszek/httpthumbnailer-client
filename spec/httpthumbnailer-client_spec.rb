require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'httpthumbnailer-client'

describe HTTPThumbnailerClient do
	it "should allow building request for thumbnail set" do
		HTTPThumbnailerClient::URIBuilder.thumbnail do
			thumbnail('crop', 16, 16, 'JPEG')
			thumbnail('pad', 32, 64, 'PNG', :magick => 'xdfa', :number => 2)
		end.should == '/thumbnail/crop,16,16,JPEG/pad,32,64,PNG,magick:xdfa,number:2'
	end
end

