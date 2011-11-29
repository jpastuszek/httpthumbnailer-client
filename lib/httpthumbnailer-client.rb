$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'httpclient'
require 'httpthumbnailer-client/multipart_response'

class HTTPThumbnailerClient
	class UnsupportedMediaTypeError < ArgumentError
	end

	class UnknownResponseType < ArgumentError
	end

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

	class Thumbnail
		def initialize(mime_type, data)
			@mime_type = mime_type
			@data = data
		end	

		attr_reader :mime_type, :data
	end

	def initialize(server_url)
		@server_url = server_url
	end

	def thumbnail(data, &block)
		uri = URIBuilder.thumbnail(&block)
		response = HTTPClient.new.request('PUT', "#{@server_url}#{uri}", nil, data)
		content_type = response.header['Content-Type'].last

		case content_type
		when 'text/plain'
			case response.status
			when 415
				raise UnsupportedMediaTypeError, response.body.delete("\r")
			when 500
			else
			end
		when /^multipart\/mixed/
			MultipartResponse.new(content_type, response.body).parts.map do |part|
				Thumbnail.new(part.header['Content-Type'], part.body)
			end
		else
			raise UnknownResponseType, content_type
		end
	end
end

