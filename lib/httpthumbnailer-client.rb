$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'httpclient'

class HTTPThumbnailerClient
	class URIBuilder
		def initialize(service_uri, &block)
			@specs = []
			@service_uri = service_uri
			instance_eval &block
		end

		def get
			"#{@service_uri}/#{@specs.join('/')}"
		end

		def self.thumbnail(&block)
			self.new('/thumbnail', &block).get
		end

		def thumbnail(method, width, height, format = 'JPEG', options = {})
			args = []
			args << method.to_s
			args << width.to_s
			args << height.to_s
			args << format.to_s

			options.keys.sort{|a, b| a.to_s <=> b.to_s}.each do |key|
				args << "#{key}:#{options[key]}"
			end

			@specs << args.join(',')
		end
	end

	def initialize(server_url)
		@service_url = service_url
	end

	def thumbnail(data, &block)
		uri = URIBuilder.thumbnail(&block)
		HTTPClient.new.put_content("#{service_url}#{uri}", data)
	end
end

