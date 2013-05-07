require 'httpclient'
require 'httpthumbnailer-client/multipart_response'

class HTTPThumbnailerClient
	InvalidThumbnailSpecificationError = Class.new ArgumentError
	ServerResourceNotFoundError = Class.new ArgumentError
	UnsupportedMediaTypeError = Class.new ArgumentError
	ImageTooLargeError = Class.new ArgumentError
	UnknownResponseType = Class.new ArgumentError
	RemoteServerError = Class.new ArgumentError

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
			self.new('/thumbnails', &block).get
		end

		def thumbnail(method, width, height, format = 'jpeg', options = {})
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

	module ThumbnailsInputMimeTypeMeta
		attr_accessor :input_mime_type
	end

	class ThumbnailingError
		def initialize(msg)
			@message = msg
		end

		attr_reader :message
	end

	def initialize(server_url, options = {})
		@server_url = server_url
		@client = HTTPClient.new
		@keep_alive = options[:keep_alive] || false
	end

	def thumbnail(data, &block)
		uri = URIBuilder.thumbnail(&block)

		response = @client.request('PUT', "#{@server_url}#{uri}", nil, data, {'Content-Type' => 'image/autodetect'})
		@client.reset_all unless @keep_alive

		content_type = response.header['Content-Type'].last

		case content_type
		when 'text/plain'
			case response.status
			when 400
				raise InvalidThumbnailSpecificationError, response.body.strip
			when 404
				raise ServerResourceNotFoundError, response.body.strip
			when 415
				raise UnsupportedMediaTypeError, response.body.strip
			when 413
				raise ImageTooLargeError, response.body.strip
			else
				raise RemoteServerError, response.body.strip
			end
		when /^multipart\/mixed/
			thumbnails = MultipartResponse.new(content_type, response.body).parts.map do |part|
				part_content_type = part.header['Content-Type']

				case part_content_type
				when 'text/plain'
					ThumbnailingError.new(part.body.delete("\r"))
				when /^image\//
					Thumbnail.new(part_content_type, part.body)
				else
					raise UnknownResponseType, part_content_type
				end
			end

			unless response.header['X-Input-Image-Content-Type'].empty?
				thumbnails.extend(ThumbnailsInputMimeTypeMeta)
				thumbnails.input_mime_type = response.header['X-Input-Image-Content-Type'].first
			end

			return thumbnails
		else
			raise UnknownResponseType, content_type
		end
	rescue HTTPClient::KeepAliveDisconnected
		raise RemoteServerError, 'empty response'
	end
end

