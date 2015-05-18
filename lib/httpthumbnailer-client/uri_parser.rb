class URIParser
	def self.parse_options(options)
		Hash[options.split(',').map.with_index do |pair, index|
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

