require 'httpclient'
require 'multipart_parser/reader'

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
			width = width.to_s
			height = height.to_s

			args = []
			args << method.to_s
			width !~ /^([0-9]+|input)$/ and raise InvalidThumbnailSpecificationError.new("bad dimension value: #{width}")
			args << width
			height !~ /^([0-9]+|input)$/ and raise InvalidThumbnailSpecificationError.new("bad dimension value: #{height}")
			args << height
			args << format.to_s

			options.keys.sort{|a, b| a.to_s <=> b.to_s}.each do |key|
				raise InvalidThumbnailSpecificationError.new("empty option key for value '#{options[key]}'") if key.nil? || key.to_s.empty? 
				raise InvalidThumbnailSpecificationError.new("missing option value for key '#{key}'") if options[key].nil? || options[key].to_s.empty? 
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

	def initialize(server_url, options = {})
		@server_url = server_url
		@client = HTTPClient.new

		# long timeouts for big image data
		@client.send_timeout = options[:send_timeout] || 300
		@client.receive_timeout = options[:receive_timeout] || 300

		# don't use keep alive by default since backend won't support it any way unless fronted with nginx or similar
		@keep_alive = options[:keep_alive] || false
	end

	attr_reader :server_url
	attr_reader :keep_alive

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
			raise error_for_status(response.status, response.body)
		when /^image\//
			Thumbnail.new(content_type, response.body)
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

	def inspect
		"#<#{self.class.name} server_url=#{server_url.inspect} keep_alive=#{keep_alive.inspect}>"
	end
end

