class HTTPThumbnailerClient
	class ThumbnailingSpec
		class EditSpec
			attr_reader :name, :args, :options

			def self.build
			end

			def self.from_string(spec)
				name, args = *spec.split(',', 2)
				name.nil? or name.empty? and raise ArgumentError, 'missing name argument'
				args = *args.split(',')

				options = args.drop_while{|a| not a.include?(':')}
				args = args.take_while{|a| not a.include?(':')}

				begin
					options = options.empty? ? {} : HTTPThumbnailerClient::ThumbnailingSpec.parse_options(options.join(','))
				rescue ArgumentError => error
					raise ArgumentError, "#{error} for edit '#{name}'"
				end
				new(name, args, options)
			end

			def initialize(name, args, options)
				@name = name
				@args = args
				@options = options
			end
		end

		attr_reader :method, :width, :height, :format, :options, :edits

		def self.build
		end

		def self.from_string(spec)
			spec, edits = *spec.split('!', 2)
			method, width, height, format, options = *spec.split(',', 5)

			method.nil? or method.empty? and raise ArgumentError, "missing method argument"
			width.nil? or width.empty? and raise ArgumentError, "missing width argument"
			height.nil? or height.empty? and raise ArgumentError, "missing height argument"
			format.nil? or format.empty? and raise ArgumentError, "missing format argument"

			width !~ /^([0-9]+|input)$/ and raise ArgumentError, "width value '#{width}' is not an integer or 'input'"
			height !~ /^([0-9]+|input)$/ and raise ArgumentError, "height value '#{height}' is not an integer or 'input'"

			options = options ? parse_options(options) : {}
			edits = edits ? edits.split('!').map{|e| EditSpec.from_string(e)} : []

			new(method, width, height, format, options, edits)
		end

		def initialize(method, width, height, format, options, edits)
			@method = method
			@width = width
			@height = height
			@format = format
			@options = options
			@edits = edits
		end

		def to_thumbnailer_uri
		end

		def self.parse_options(options)
			Hash[options.to_s.split(',').map.with_index do |pair, index|
				pair.empty? and raise ArgumentError, "missing key-value pair on position #{index + 1}"
				pair.split(':', 2)
			end].tap do |map|
				map.each do |key, value|
					key.nil? or key.empty? and raise ArgumentError, "missing option key name for value '#{value}'"
					value.nil? or value.empty? and raise ArgumentError, "missing option key value for key '#{key}'"
				end
			end
		end
	end
end

