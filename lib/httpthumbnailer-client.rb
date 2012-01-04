$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'httpclient'
require 'httpthumbnailer-client/multipart_response'

class HTTPThumbnailerClient
	class UnsupportedMediaTypeError < ArgumentError
	end

	class ImageTooLargeError < ArgumentError
	end

	class UnknownResponseType < ArgumentError
	end

	class RemoteServerError < ArgumentError
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

	module ThumbnailsInputMimeTypeMeta
		attr_accessor :input_mime_type
	end

	class ThumbnailingError
		def initialize(msg)
			@message = msg
			@type = msg.match(/Error: (.*?): /)[1] rescue NoMethodError
		end

		attr_reader :type, :message
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
			when 413
				raise ImageTooLargeError, response.body.delete("\r")
			else
				raise RemoteServerError, response.body.delete("\r")
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
	end
end

