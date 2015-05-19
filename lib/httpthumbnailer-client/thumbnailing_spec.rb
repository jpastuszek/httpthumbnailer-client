class HTTPThumbnailerClient
	#TODO: support for escaping of ! and ,
	class ThumbnailingSpec
		class MissingArgumentError < ArgumentError
			def initialize(argument)
				super "missing #{argument} argument"
			end
		end

		class InvalidArgumentValueError < ArgumentError
			def initialize(name, value, reason)
				super "#{name} value '#{value}' is not #{reason}"
			end
		end

		class InvalidOptionsFormatError < ArgumentError
			def for_edit(name)
				exception "#{message} for edit '#{name}'"
			end
		end

		class MissingOptionKeyValuePairError < InvalidOptionsFormatError
			def initialize(index)
				super "missing key-value pair on position #{index + 1}"
			end
		end

		class MissingOptionKeyNameError < InvalidOptionsFormatError
			def initialize(value)
				super "missing option key name for value '#{value}'"
			end
		end

		class MissingOptionKeyValueError < InvalidOptionsFormatError
			def initialize(key)
				super "missing option key value for key '#{key}'"
			end
		end

		class EditSpec
			attr_reader :name, :args, :options

			def self.build
			end

			def self.from_string(spec)
				name, args = *spec.split(',', 2)
				name.nil? or name.empty? and raise MissingArgumentError, 'edit name'
				args = *args.split(',')

				options = args.drop_while{|a| not a.include?(':')}
				args = args.take_while{|a| not a.include?(':')}

				begin
					options = options.empty? ? {} : HTTPThumbnailerClient::ThumbnailingSpec.parse_options(options.join(','))
				rescue InvalidOptionsFormatError => error
					raise error.for_edit(name)
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

			method.nil? or method.empty? and raise MissingArgumentError, 'method'
			width.nil? or width.empty? and raise MissingArgumentError, 'width'
			height.nil? or height.empty? and raise MissingArgumentError, 'height'
			format.nil? or format.empty? and raise MissingArgumentError, 'format'

			width !~ /^([0-9]+|input)$/ and raise InvalidArgumentValueError.new('width', width, "an integer or 'input'")
			height !~ /^([0-9]+|input)$/ and raise InvalidArgumentValueError.new('height', height, "an integer or 'input'")

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
				pair.empty? and raise MissingOptionKeyValuePairError, index
				pair.split(':', 2)
			end].tap do |map|
				map.each do |key, value|
					key.nil? or key.empty? and raise MissingOptionKeyNameError, value
					value.nil? or value.empty? and raise MissingOptionKeyValueError, key
				end
			end
		end
	end
end

