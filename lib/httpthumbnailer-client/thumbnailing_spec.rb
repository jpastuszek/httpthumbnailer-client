class HTTPThumbnailerClient
	#TODO: support for escaping of ! and ,
	class ThumbnailingSpec
		class Builder
			def initialize(method, width, height, format = 'jpeg', options = {}, &block)
				@spec = ThumbnailingSpec.new(method, width.to_s, height.to_s, format, options)
				instance_eval(&block) if block
			end

			def edit(name, *args)
				edit_options, args = *args.partition{|e| e.kind_of? Hash}
				edit_options = edit_options.each.with_object({}) do |opt, hash|
					hash.merge! opt
				end

				edit_spec ThumbnailingSpec::EditSpec.new(name, args, edit_options)
				self
			end

			def edit_spec(spec)
				@spec.edits << spec
				self
			end

			attr_reader :spec

			def to_s
				@spec.to_s
			end
		end

		class InvalidFormatError < ArgumentError
			def for_edit(name)
				exception "#{message} for edit '#{name}'"
			end
		end

		class MissingArgumentError < InvalidFormatError
			def initialize(argument)
				super "missing #{argument} argument"
			end
		end

		class InvalidArgumentValueError < InvalidFormatError
			def initialize(name, value, reason)
				super "#{name} value '#{value}' is not #{reason}"
			end
		end

		class MissingOptionKeyValuePairError < InvalidFormatError
			def initialize(index)
				super "missing key-value pair on position #{index + 1}"
			end
		end

		class MissingOptionKeyNameError < InvalidFormatError
			def initialize(value)
				super "missing option key name for value '#{value}'"
			end
		end

		class MissingOptionKeyValueError < InvalidFormatError
			def initialize(key)
				super "missing option value for key '#{key}'"
			end
		end

		class EditSpec
			attr_reader :name, :args, :options

			def self.from_string(string)
				args = HTTPThumbnailerClient::ThumbnailingSpec.split_args(string)
				args, options = HTTPThumbnailerClient::ThumbnailingSpec.partition_args_options(args)
				name = args.shift

				begin
					options = HTTPThumbnailerClient::ThumbnailingSpec.parse_options(options)
				rescue InvalidFormatError => error
					raise error.for_edit(name)
				end
				new(name, args, options)
			end

			def initialize(name, args, options = {})
				name.nil? or name.empty? and raise MissingArgumentError, 'edit name'

				@name = name
				@args = args
				@options = options
			end

			def to_s
				begin
					[@name, *@args, *HTTPThumbnailerClient::ThumbnailingSpec.options_to_s(@options)].join(',')
				rescue InvalidFormatError => error
					raise error.for_edit(name)
				end
			end
		end

		attr_reader :method, :width, :height, :format, :options, :edits

		def self.from_string(string)
			edits = split_edits(string)
			spec = edits.shift
			args = split_args(spec)
			args, options = partition_args_options(args)
			method, width, height, format = *args.shift(4) # ignore extra args

			options = parse_options(options)
			edits = edits.map{|e| EditSpec.from_string(e)}

			new(method, width, height, format, options, edits)
		end

		def initialize(method, width, height, format, options = {}, edits = [])
			method.nil? or method.empty? and raise MissingArgumentError, 'method'
			width.nil? or width.empty? and raise MissingArgumentError, 'width'
			height.nil? or height.empty? and raise MissingArgumentError, 'height'
			format.nil? or format.empty? and raise MissingArgumentError, 'format'

			width !~ /^([0-9]+|input)$/ and raise InvalidArgumentValueError.new('width', width, "an integer or 'input'")
			height !~ /^([0-9]+|input)$/ and raise InvalidArgumentValueError.new('height', height, "an integer or 'input'")
			@method = method
			@width = width
			@height = height
			@format = format
			@options = options
			@edits = edits
		end

		def to_s
			[[@method, @width, @height, @format, *self.class.options_to_s(@options)].join(','), *@edits.map(&:to_s)].join('!')
		end

		def self.split_edits(string)
			string.split('!')
		end

		def self.split_args(string)
			string.split(',')
		end

		def self.partition_args_options(args)
			options = args.drop_while{|a| not a.include?(':')}
			args = args.take_while{|a| not a.include?(':')}
			[args, options]
		end

		def self.parse_options(options)
			Hash[options.map.with_index do |pair, index|
				pair.empty? and raise MissingOptionKeyValuePairError, index
				pair.split(':', 2)
			end].tap do |map|
				map.each do |key, value|
					key.nil? or key.empty? and raise MissingOptionKeyNameError, value
					value.nil? or value.empty? and raise MissingOptionKeyValueError, key
				end
			end
		end

		def self.options_to_s(options)
			options.sort_by{|k,v| k}.map do |key, value|
				raise MissingOptionKeyNameError, value if key.nil? or key.to_s.empty?
				raise MissingOptionKeyValueError, key if value.nil? or value.to_s.empty?
				key = key.to_s.gsub('_', '-') if key.kind_of? Symbol
				"#{key}:#{value}"
			end
		end
	end
end

