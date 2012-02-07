# httpthumbnailer-client

Ruby client to [httpthumbnailer](http://github.com/jpastuszek/httpthumbnailer) image scaling and conversion HTTP API server.

## Installing

    gem install httpthumbnailer-client

## Usage

Basic usage:

```ruby
require 'httpthumbnailer-client'

# read orginal image data (may be any format supported by ImageMagick installation on the server)
data = File.read('image_file.jpg')

# thumbnail image with API server listening on localhost port 3100
thumbnails = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail(data) do
	# definition of thumbnail formats - see the API server documentation of available operations, formats and options
	thumbnail 'crop', 6, 3, 'JPEG' 
	thumbnail 'crop', 8, 8, 'PNG'
	thumbnail 'pad', 4, 4, 'PNG'
end

thumbnails[0].mime_type 	# => 'image/jpeg'
thumbnails[0].data 			# => 6x3 thumbnail JPEG data Strine

thumbnails[1].mime_type 	# => 'image/png'
thumbnails[1].data 			# => 8x8 thumbnail PNG data String

thumbnails[2].mime_type		# => 'image/png'
thumbnails[2].data			# => 4x4 thumbnail PNG data String

thumbs.input_mime_type	# => 'image/jpeg' - detected input image format by API server (content based)
```

For more details see [RSpec tests](http://github.com/jpastuszek/httpthumbnailer-client/blob/master/spec/httpthumbnailer-client_spec.rb)

## Contributing to httpthumbnailer-client
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Jakub Pastuszek. See LICENSE.txt for
further details.

