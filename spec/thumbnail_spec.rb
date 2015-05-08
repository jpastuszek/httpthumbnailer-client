require_relative 'spec_helper'

describe HTTPThumbnailerClient, 'single thumbnail API' do
	before :all do
		log = support_dir + 'server.log'
		start_server(
			"httpthumbnailer -f -d -x XID -l #{log}",
			'/tmp/httpthumbnailer.pid',
			log,
			'http://localhost:3100/'
		)
	end

	after :all do
		stop_server('/tmp/httpthumbnailer.pid')
	end

	it 'should return single thumbnail matching specification' do
		thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')

		thumbnail.should be_kind_of HTTPThumbnailerClient::Thumbnail
		thumbnail.mime_type.should == 'image/jpeg'
		thumbnail.width.should == 6
		thumbnail.height.should == 3

		i = identify(thumbnail.data)
		i.format.should == 'JPEG'
		i.width.should == 6
		i.height.should == 3
	end

	describe 'meta data' do
		it 'should provide input image mime type' do
			thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			thumbnail.input_mime_type.should == 'image/jpeg'
		end

		it 'should provide input image size' do
			thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			thumbnail.input_width.should == 509
			thumbnail.input_height.should == 719
		end
	end

	describe 'general error handling' do
		it 'should raise HTTPThumbnailerClient::InvalidThumbnailSpecificationError error on bad request error' do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read, 'crop', 0, 0, 'jpeg')
			}.should raise_error HTTPThumbnailerClient::InvalidThumbnailSpecificationError

			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.jpg').read, 'blah', 4, 4, 'jpeg')
			}.should raise_error HTTPThumbnailerClient::InvalidThumbnailSpecificationError
		end

		it 'should raise HTTPThumbnailerClient::ServerResourceNotFoundError error on not found error' do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100/blah').thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			}.should raise_error HTTPThumbnailerClient::ServerResourceNotFoundError
		end

		it 'should raise HTTPThumbnailerClient::UnsupportedMediaTypeError error on unsupported media type error' do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test.txt').read, 'crop', 6, 3, 'jpeg')
			}.should raise_error HTTPThumbnailerClient::UnsupportedMediaTypeError
		end

		it 'should raise HTTPThumbnailerClient::ImageTooLargeError error on request entity too large error' do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').thumbnail((support_dir + 'test-large.jpg').read, 'crop', 7000, 7000, 'png')
			}.should raise_error HTTPThumbnailerClient::ImageTooLargeError
		end
	end

	describe 'passing custom HTTP request headers' do
		it 'should add headers provided with :headers option' do
			xid = rand(0..1000)

			thumbnail = HTTPThumbnailerClient.new('http://localhost:3100', headers: {'XID' => xid}).thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			thumbnail.should be_kind_of HTTPThumbnailerClient::Thumbnail

			(support_dir + 'server.log').read.should include "\"xid\":\"#{xid}\""
		end

		it '#with_headers should add headers to given request' do
			xid = rand(0..1000)

			thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').with_headers('XID' => xid).thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			thumbnail.should be_kind_of HTTPThumbnailerClient::Thumbnail

			(support_dir + 'server.log').read.should include "\"xid\":\"#{xid}\""

			xid = rand(1000..2000)

			thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').with_headers('XID' => xid).thumbnail((support_dir + 'test.jpg').read, 'crop', 6, 3, 'jpeg')
			thumbnail.should be_kind_of HTTPThumbnailerClient::Thumbnail

			(support_dir + 'server.log').read.should include "\"xid\":\"#{xid}\""
		end
	end
end

