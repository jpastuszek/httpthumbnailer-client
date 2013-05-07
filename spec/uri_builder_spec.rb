require_relative 'spec_helper'

describe HTTPThumbnailerClient::URIBuilder do
	it 'should allow building request for single thumbnail' do
		HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', magick: 'xdfa', number: 2)
		.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2'
	end

	it 'should allow building request for thumbnail set' do
		HTTPThumbnailerClient::URIBuilder.thumbnails do
			thumbnail 'crop', 16, 16, 'jpeg' 
			thumbnail 'pad', 32, 64, 'png', magick: 'xdfa', number: 2
		end.should == '/thumbnails/crop,16,16,jpeg/pad,32,64,png,magick:xdfa,number:2'
	end
end

