require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'httpthumbnailer-client'

describe HTTPThumbnailerClient::URIBuilder do
	it "should allow building request for thumbnail set" do
		HTTPThumbnailerClient::URIBuilder.thumbnail do
			thumbnail 'crop', 16, 16, 'jpeg' 
			thumbnail 'pad', 32, 64, 'png', :magick => 'xdfa', :number => 2
		end.should == '/thumbnails/crop,16,16,jpeg/pad,32,64,png,magick:xdfa,number:2'
	end
end

describe HTTPThumbnailerClient do
	before :all do
		log = spec_dir + 'server.log'
		start_server(
			"httpthumbnailer -f -d -l #{log}",
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
			thumbnail 'crop', 6, 3, 'jpeg' 
			thumbnail 'crop', 8, 8, 'png'
			thumbnail 'crop', 4, 4, 'png'
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

	describe "meta data" do
		it "should provide input image mime type" do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
				thumbnail 'crop', 6, 3, 'jpeg' 
			end
			thumbs.input_mime_type.should == 'image/jpeg'
		end
	end

	describe 'general error handling' do
		it "should raise HTTPThumbnailerClient::ServerResourceNotFoundError error on 404 server error" do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100/blah').thumbnail((spec_dir + 'test.jpg').read) do
					thumbnail 'crop', 6, 3, 'jpeg' 
				end
			}.should raise_error HTTPThumbnailerClient::ServerResourceNotFoundError
		end

		it "should raise HTTPThumbnailerClient::UnsupportedMediaTypeError error on unsupported media type" do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.txt').read) do
					thumbnail 'crop', 6, 3, 'jpeg' 
					thumbnail 'crop', 8, 8, 'png'
				end
			}.should raise_error HTTPThumbnailerClient::UnsupportedMediaTypeError
		end

		it "should raise HTTPThumbnailerClient::ImageTooLargeError error on too large image data to fit in memory limits" do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test-large.jpg').read) do
					thumbnail 'crop', 6, 3, 'jpeg' 
					thumbnail 'crop', 7000, 7000, 'png'
				end
			}.should raise_error HTTPThumbnailerClient::ImageTooLargeError
		end

	end

	describe 'thumbnailing error handling' do
		it "should return HTTPThumbnailerClient::ThumbnailingError object with set of returned thumbnail in case of error with particluar thumbanil" do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
				thumbnail 'crop', 6, 3, 'jpeg' 
				thumbnail 'crop', 0, 0, 'png'
				thumbnail 'crop', 4, 4, 'png'
			end

			thumbs[0].should be_kind_of HTTPThumbnailerClient::Thumbnail
			thumbs[0].mime_type.should == 'image/jpeg'
			i = identify(thumbs[0].data)
			i.format.should == 'JPEG'
			i.width.should == 6
			i.height.should == 3

			thumbs[1].should be_kind_of HTTPThumbnailerClient::ThumbnailingError
			thumbs[1].message.should =~ /^Error: at least one image dimension is zero/

			thumbs[2].should be_kind_of HTTPThumbnailerClient::Thumbnail
			thumbs[2].mime_type.should == 'image/png'
			i = identify(thumbs[2].data)
			i.format.should == 'PNG'
			i.width.should == 4
			i.height.should == 4
		end

		it "should return HTTPThumbnailerClient::ThumbnailingError object with set of returned thumbnail in case of memory exhaustion while thumbnailing" do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((spec_dir + 'test.jpg').read) do
				thumbnail 'crop', 6, 3, 'jpeg' 
				thumbnail 'crop', 16000, 16000, 'png'
				thumbnail 'crop', 4, 4, 'png'
			end

			thumbs[0].should be_kind_of HTTPThumbnailerClient::Thumbnail
			thumbs[0].mime_type.should == 'image/jpeg'
			i = identify(thumbs[0].data)
			i.format.should == 'JPEG'
			i.width.should == 6
			i.height.should == 3

			thumbs[1].should be_kind_of HTTPThumbnailerClient::ThumbnailingError
			thumbs[1].message.should =~ /^Error: image too large/

			thumbs[2].should be_kind_of HTTPThumbnailerClient::Thumbnail
			thumbs[2].mime_type.should == 'image/png'
			i = identify(thumbs[2].data)
			i.format.should == 'PNG'
			i.width.should == 4
			i.height.should == 4
		end
	end
end

