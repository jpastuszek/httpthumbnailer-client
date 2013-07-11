# HTTP Thubnailer Client

Ruby client to [httpthumbnailer](http://github.com/jpastuszek/httpthumbnailer) image scaling and conversion HTTP API server.

## Installing

```bash
gem install httpthumbnailer-client
```

## Usage

### Ruby API

```ruby
require 'httpthumbnailer-client'

# read original image data (may be any format supported by ImageMagick/GraphicsMagick installation on the server)
data = File.read('image_file.jpg')

# with API server listening on localhost port 3100
# see the API server documentation for available operations, formats and options

# generate single thumbnail from image data (single thumbnail API)
thumbnail = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail(data, 'crop', 60, 30, 'jpeg')
thumbnail.mime_type 	# => 'image/jpeg'
thumbnail.data 			# => 60x30 thumbnail JPEG data String

# generate set of thumbnails from image data (multipart API)
thumbnails = HTTPThumbnailerClient.new('http://localhost:3100').thumbnail(data) do
	thumbnail 'crop', 60, 30, 'jpeg' 
	thumbnail 'crop', 80, 80, 'png'
	thumbnail 'pad', 40, 40, 'png'
end

thumbnails[0].mime_type 	# => 'image/jpeg'
thumbnails[0].data 			# => 60x30 thumbnail JPEG data String

thumbnails[1].mime_type 	# => 'image/png'
thumbnails[1].data 			# => 80x80 thumbnail PNG data String

thumbnails[2].mime_type		# => 'image/png'
thumbnails[2].data			# => 40x40 thumbnail PNG data String

thumbnails.input_mime_type	# => 'image/jpeg' - detected input image format by API server (content based)
```

For more details see RSpec for [single thumbnail API](http://github.com/jpastuszek/httpthumbnailer-client/blob/master/spec/thumbnail_spec.rb) and [multipart API](http://github.com/jpastuszek/httpthumbnailer-client/blob/master/spec/thumbnails_spec.rb).

### CLI tool

This gem provides `httpthumbnailer-client` command line tool that can be used to thumbnail images via [httpthumbnailer](http://github.com/jpastuszek/httpthumbnailer).

```bash
# start thumbnailing server (to stop: kill `cat httpthumbnailer.pid`)
httpthumbnailer

# thumbnail to standard output
cat ~/Pictures/compute.jpg | httpthumbnailer-client -t crop,100,200,png > thumbnail.png

# generate multiple thumbnails
cat ~/Pictures/compute.jpg | httpthumbnailer-client -t crop,100,200,jpeg,quality:100 -t pad,200,200,png thumbnail1.jpg thumbnail2.png
```

## Contributing to HTTP Thubnailer Client
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Jakub Pastuszek. See LICENSE.txt for
further details.

