require_relative 'spec_helper'

describe HTTPThumbnailerClient, 'multipart API' do
	before :all do
		log = support_dir + 'server.log'
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

	it 'should return set of thumbnails matching specifications' do
		thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read) do
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

	describe 'meta data' do
		it 'should provide input image mime type' do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read) do
				thumbnail 'crop', 6, 3, 'jpeg' 
			end
			thumbs.input_mime_type.should == 'image/jpeg'
		end
	end

	describe 'returns HTTPThumbnailerClient::ThumbnailingError object within set of returned thumbnails' do
		it 'in case of error with particluar thumbanil' do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read) do
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

		it 'in case of memory exhaustion while thumbnailing' do
			thumbs = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read) do
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

