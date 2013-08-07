require_relative 'spec_helper'

describe HTTPThumbnailerClient, 'identify API' do
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

	it 'should return input image identification information' do
		input_id = HTTPThumbnailerClient.new('http://localhost:3100').identify((support_dir + 'test.jpg').read)
		input_id.mime_type.should == 'image/jpeg'
		input_id.width.should == 509
		input_id.height.should == 719
	end

	describe 'general error handling' do
		it 'should raise HTTPThumbnailerClient::UnsupportedMediaTypeError error on unsupported media type error' do
			lambda {
				HTTPThumbnailerClient.new('http://localhost:3100').identify((support_dir + 'test.txt').read)
			}.should raise_error HTTPThumbnailerClient::UnsupportedMediaTypeError
		end
	end
end

