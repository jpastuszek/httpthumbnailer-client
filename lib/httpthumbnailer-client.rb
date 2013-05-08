require 'httpclient'
require 'multipart_parser/reader'

class HTTPThumbnailerClient
	InvalidThumbnailSpecificationError = Class.new ArgumentError
	ServerResourceNotFoundError = Class.new ArgumentError
	UnsupportedMediaTypeError = Class.new ArgumentError
	ImageTooLargeError = Class.new ArgumentError
	UnknownResponseType = Class.new ArgumentError
	RemoteServerError = Class.new ArgumentError
	InvalidMultipartResponseError = Class.new ArgumentError

	class URIBuilder
		def initialize(service_uri, &block)
			@specs = []
			@service_uri = service_uri
			instance_eval &block if block
		end

		def get
			"#{@service_uri}/#{@specs.join('/')}"
		end

		def self.thumbnail(*spec)
			self.new('/thumbnail').thumbnail(*spec).get
		end

		def self.thumbnails(&block)
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
			self
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

	def thumbnail(data, *spec, &block)
		uri = if block
			URIBuilder.thumbnails(&block)
		else
			URIBuilder.thumbnail(*spec)
		end

		response = @client.request('PUT', "#{@server_url}#{uri}", nil, data, {'Content-Type' => 'image/autodetect'})
		@client.reset_all unless @keep_alive

		content_type = response.header['Content-Type'].last

		thumbnails = case content_type
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
		when /^image\//
			Thumbnail.new(content_type, response.body)
		when /^multipart\/mixed/
			parts = []
			parser = MultipartParser::Reader.new(MultipartParser::Reader.extract_boundary_value(content_type))
			parser.on_part do |part|
				part_content_type = part.headers['content-type'] or raise InvalidMultipartResponseError, 'missing Content-Type header in multipart part'
				part.on_data do |data|
					case part_content_type
					when 'text/plain'
						parts << ThumbnailingError.new(data.strip)
					when /^image\//
						parts << Thumbnail.new(part_content_type, data)
					else
						raise UnknownResponseType, part_content_type
					end
				end
			end

			parser.write response.body
			parser.ended? or raise InvalidMultipartResponseError, 'truncated multipart message'
			parts
		else
			raise UnknownResponseType, content_type
		end

		unless response.header['X-Input-Image-Content-Type'].empty?
			thumbnails.extend(ThumbnailsInputMimeTypeMeta)
			thumbnails.input_mime_type = response.header['X-Input-Image-Content-Type'].first
		end

		return thumbnails
	rescue HTTPClient::KeepAliveDisconnected
		raise RemoteServerError, 'empty response'
	end
end

