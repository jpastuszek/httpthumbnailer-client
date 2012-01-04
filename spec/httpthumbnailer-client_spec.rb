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
		log = spec_dir + 'server.log'
		log.truncate(0)
		
		start_server(
			"httpthumbnailer",
			'/tmp/httpthumbnailer.pid',
			log,
			'http://localhost:3100/'
		)
	end

	after :all do
		stop_server('/tmp/httpthumbnailer.pid')
	end

	it "should return set of thumbnails matching specified specification" do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
			thumbnail 'crop', 6, 3, 'JPEG' 
			thumbnail 'crop', 8, 8, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end

		thumbs[0].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[0].mime_type.should == 'image/jpeg'
		i = identify(thumbs[0].data)
		i.format.should == 'JPEG'
		i.width.should == 6
		i.height.should == 3

		thumbs[1].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[1].mime_type.should == 'image/png'
		i = identify(thumbs[1].data)
		i.format.should == 'PNG'
		i.width.should == 8
		i.height.should == 8

		thumbs[2].should be_kind_of HTTPThumbnailerClient::Thumbnail
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

	it "should raise HTTPThumbnailerClient::ImageTooLargeError error on too large image data to fit in memory limits" do
		lambda {
			HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test-large.jpg').read) do
				thumbnail 'crop', 6, 3, 'JPEG' 
				thumbnail 'crop', 7000, 7000, 'PNG'
			end
		}.should raise_error HTTPThumbnailerClient::ImageTooLargeError
	end

	it "should raise HTTPThumbnailerClient::RemoteServerError error on 404 server error" do
		lambda {
			HTTPThumbnailerClient.new('http://localhost:3100/blah').thumbnail((spec_dir + 'test.jpg').read) do
				thumbnail 'crop', 6, 3, 'JPEG' 
			end
		}.should raise_error HTTPThumbnailerClient::RemoteServerError
	end

	it "should return HTTPThumbnailerClient::ThumbnailingError object with set of returned thumbnail in case of error with particluar thumbanil" do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
			thumbnail 'crop', 6, 3, 'JPEG' 
			thumbnail 'crop', 0, 0, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end

		thumbs[0].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[0].mime_type.should == 'image/jpeg'
		i = identify(thumbs[0].data)
		i.format.should == 'JPEG'
		i.width.should == 6
		i.height.should == 3

		thumbs[1].should be_kind_of HTTPThumbnailerClient::ThumbnailingError
		thumbs[1].type.should == "ArgumentError"
		thumbs[1].message.should == "Error: ArgumentError: invalid result dimension (0, 0 given)\n"

		thumbs[2].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[2].mime_type.should == 'image/png'
		i = identify(thumbs[2].data)
		i.format.should == 'PNG'
		i.width.should == 4
		i.height.should == 4
	end

	it "should return HTTPThumbnailerClient::ThumbnailingError object with set of returned thumbnail in case of memory exhaustion while thumbnailing" do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
			thumbnail 'crop', 6, 3, 'JPEG' 
			thumbnail 'crop', 16000, 16000, 'PNG'
			thumbnail 'crop', 4, 4, 'PNG'
		end

		thumbs[0].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[0].mime_type.should == 'image/jpeg'
		i = identify(thumbs[0].data)
		i.format.should == 'JPEG'
		i.width.should == 6
		i.height.should == 3

		thumbs[1].should be_kind_of HTTPThumbnailerClient::ThumbnailingError
		thumbs[1].type.should == "Thumbnailer::ImageTooLargeError"
		thumbs[1].message.should =~ /^Error: Thumbnailer::ImageTooLargeError:/

		thumbs[2].should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbs[2].mime_type.should == 'image/png'
		i = identify(thumbs[2].data)
		i.format.should == 'PNG'
		i.width.should == 4
		i.height.should == 4
	end
end

