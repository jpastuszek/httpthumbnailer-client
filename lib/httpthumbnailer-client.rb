require 'httpclient'
require 'ostruct'
require 'json'
require 'multipart_parser/reader'
require 'httpthumbnailer-client/uri_builder'

class HTTPThumbnailerClient
	HTTPThumbnailerClientError = Class.new(ArgumentError)

	InvalidThumbnailSpecificationError = Class.new(HTTPThumbnailerClientError)
	ServerResourceNotFoundError = Class.new(HTTPThumbnailerClientError)
	UnsupportedMediaTypeError = Class.new(HTTPThumbnailerClientError)
	ImageTooLargeError = Class.new(HTTPThumbnailerClientError)
	RemoteServerError = Class.new(HTTPThumbnailerClientError)

	@@errors = {}

	module Status
		def status=(st)
			@status = st
		end

		def status
			@status
		end

		module Instance
			def status
				defined?(self.class.status) ? self.class.status : 500
			end
		end

		def self.extended(klass)
			klass.instance_eval do
				include Instance
			end
		end
	end

	def self.assign_status_code(error, status)
		error.extend Status
		error.status = status
		@@errors[status] = error
		@@errors[error] = status
	end

	assign_status_code(InvalidThumbnailSpecificationError, 400)
	assign_status_code(ServerResourceNotFoundError, 404)
	assign_status_code(UnsupportedMediaTypeError, 415)
	assign_status_code(ImageTooLargeError, 413)
	assign_status_code(RemoteServerError, 500)

	def error_for_status(status, body)
		@@errors.fetch(status){|err| RemoteServerError}.new(body)
	end

	UnknownResponseType = Class.new HTTPThumbnailerClientError
	InvalidMultipartResponseError = Class.new HTTPThumbnailerClientError

	class Thumbnail
		def initialize(mime_type, width, height, data)
			@mime_type = mime_type
			@data = data

			# added to thumbnailer v1.1.0 so may be nil for older server
			@width = width.to_i if width
			@height = height.to_i if height
		end

		attr_reader :mime_type
		attr_reader :width
		attr_reader :height
		attr_reader :data
	end

	module ThumbnailsInputIdentifyMeta
		attr_accessor :input_mime_type

		# added to thumbnailer v1.1.0 so may be nil for older server
		attr_accessor :input_width
		attr_accessor :input_height
	end

	class ImageID
		def initialize(body)
			id = JSON.load(body)
			@mime_type = id['mimeType']
			@width = id['width']
			@height = id['height']
		end

		attr_reader :mime_type
		attr_reader :width
		attr_reader :height
	end

	def initialize(server_url, options = {})
		@server_url = server_url
		@client = HTTPClient.new

		# long timeouts for big image data
		@client.send_timeout = options[:send_timeout] || 300
		@client.receive_timeout = options[:receive_timeout] || 300

		# additional HTTP headers to be passed with requests
		@headers = options[:headers] || {}

		# don't use keep alive by default since backend won't support it any way unless fronted with nginx or similar
		@keep_alive = options[:keep_alive] || false
	end

	attr_reader :server_url
	attr_reader :keep_alive

	def thumbnail(data, *spec, &block)
		uri = if spec.empty?
			URIBuilder.thumbnails(&block)
		else
			URIBuilder.thumbnail(*spec, &block)
		end

		response = @client.request('PUT', "#{@server_url}#{uri}", nil, data, {'Content-Type' => 'image/autodetect'}.merge(@headers))
		@client.reset_all unless @keep_alive

		content_type = response.header['Content-Type'].last

		thumbnails = case content_type
		when 'text/plain'
			raise error_for_status(response.status, response.body)
		when /^image\//
			Thumbnail.new(content_type, response.headers['X-Image-Width'], response.headers['X-Image-Height'], response.body)
		when /^multipart\/mixed/
			parts = []
			parser = MultipartParser::Reader.new(MultipartParser::Reader.extract_boundary_value(content_type))
			parser.on_part do |part|
				part_content_type = part.headers['content-type'] or raise InvalidMultipartResponseError, 'missing Content-Type header in multipart part'
				part_status = part.headers['status']
				data = ''

				part.on_data do |partial_data|
					data << partial_data
				end

				part.on_end do
					case part_content_type
					when 'text/plain'
						part_status or raise InvalidMultipartResponseError, 'missing Status header in error part (text/plain)'

						begin
							raise error_for_status(part_status.to_i, data.strip)
						rescue HTTPThumbnailerClientError => error # raise for stack trace
							parts << error
						end
					when /^image\//
						parts << Thumbnail.new(part_content_type, part.headers['x-image-width'], part.headers['x-image-height'], data)
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

		thumbnails.extend(ThumbnailsInputIdentifyMeta)
		thumbnails.input_mime_type = response.header['X-Input-Image-Content-Type'].first unless response.header['X-Input-Image-Content-Type'].empty? # deprecated
		thumbnails.input_mime_type = response.header['X-Input-Image-Mime-Type'].first unless response.header['X-Input-Image-Mime-Type'].empty?
		thumbnails.input_width = response.header['X-Input-Image-Width'].first.to_i unless response.header['X-Input-Image-Width'].empty?
		thumbnails.input_height = response.header['X-Input-Image-Height'].first.to_i unless response.header['X-Input-Image-Height'].empty?

		return thumbnails
	rescue HTTPClient::KeepAliveDisconnected
		raise RemoteServerError, 'empty response'
	end

	def identify(data)
		response = @client.request('PUT', "#{@server_url}/identify", nil, data, {'Content-Type' => 'image/autodetect'}.merge(@headers))
		@client.reset_all unless @keep_alive

		content_type = response.header['Content-Type'].last

		image_id = case content_type
		when 'text/plain'
			raise error_for_status(response.status, response.body)
		when 'application/json'
			ImageID.new(response.body)
		else
			raise UnknownResponseType, content_type
		end

		return image_id
	rescue HTTPClient::KeepAliveDisconnected
		raise RemoteServerError, 'empty response'
	end

	attr_accessor :headers

	def with_headers(headers)
		n = self.dup
		n.headers = @headers.merge headers
		n
	end

	def inspect
		"#<#{self.class.name} server_url=#{server_url.inspect} keep_alive=#{keep_alive.inspect}>"
	end
end

