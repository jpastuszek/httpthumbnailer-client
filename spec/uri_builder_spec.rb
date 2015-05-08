require_relative 'spec_helper'

describe HTTPThumbnailerClient::URIBuilder do
	it 'should allow building request for single thumbnail' do
		HTTPThumbnailerClient::URIBuilder.thumbnail('pad', 32, 64, 'png', {magick: 'xdfa', number: 2})
		.should == '/thumbnail/pad,32,64,png,magick:xdfa,number:2'
	end

	it 'should allow building request for thumbnail set' do
		HTTPThumbnailerClient::URIBuilder.thumbnails do
			thumbnail 'crop', 16, 16, 'jpeg'
			thumbnail 'pad', 32, 64, 'png', {magick: 'xdfa', number: 2}
		end.should == '/thumbnails/crop,16,16,jpeg/pad,32,64,png,magick:xdfa,number:2'
	end

	it 'should allow building request for thumbnail set with edits' do
		HTTPThumbnailerClient::URIBuilder.thumbnails do
			thumbnail 'crop', 16, 16, 'jpeg', {}, [['test', '1', '2'], ['test2', {'b' => 2, 'a' => 1}]]
			thumbnail 'pad', 32, 64, 'png', {magick: 'xdfa', number: 2}
			thumbnail 'fit', 16, 16, 'jpeg', {}, [['test', '1', '2', {'b' => 2, 'a' => 1}]]
		end.should == '/thumbnails/crop,16,16,jpeg!test,1,2!test2,a:1,b:2/pad,32,64,png,magick:xdfa,number:2/fit,16,16,jpeg!test,1,2,a:1,b:2'
	end
end

