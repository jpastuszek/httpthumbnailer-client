require_relative 'thumbnail_spec'

class HTTPThumbnailerClient
	class URIBuilder
		def initialize(&block)
			@specs = []
			instance_eval(&block) if block
		end

		def self.thumbnail(method, width, height, format = 'jpeg', options = {}, &block)
			self.new.thumbnail(method, width, height, format, options, &block).to_s
		end

		def self.thumbnails(&block)
			self.new(&block).to_s
		end

		def self.specs(*specs)
			specs.each.with_object(new) do |spec, builder|
				builder.thumbnail_spec spec
			end.to_s
		end

		def thumbnail(method, width, height, format = 'jpeg', options = {}, &block)
			thumbnail_spec ThumbnailSpec::Builder.new(method, width.to_s, height.to_s, format, options, &block).spec
			self
		end

		def thumbnail_spec(spec)
			@specs << spec
		end

		attr_reader :specs

		def to_s
			uri = @specs.length > 1 ? '/thumbnails' : '/thumbnail'
			"#{uri}/#{@specs.map(&:to_s).join('/')}"
		end

		alias :get :to_s
	end
end

