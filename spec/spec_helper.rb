$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

require 'httpthumbnailer-client'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

require 'daemon'
require 'RMagick'

def gem_dir
	Pathname.new(__FILE__).dirname + '..'
end

def spec_dir
	gem_dir + 'spec'
end

def support_dir
	spec_dir + 'support'
end

def identify(data)
	image = Magick::Image.from_blob(data).first
	out = Struct.new(:format, :width, :height).new(image.format, image.columns, image.rows)
	image.destroy!
	out
end

def pixel_color(data, x, y)
	image = Magick::Image.from_blob(data).first
	out = image.pixel_color(x.to_i, y.to_i).to_color.sub(/^#/, '0x')
	image.destroy!
	out
end

def get(url)
	HTTPClient.new.get_content(url)
end

def start_server(cmd, pid_file, log_file, test_url)
	fork do
		Daemon.daemonize(pid_file, log_file)
		log_file = Pathname.new(log_file)
		log_file.truncate(0) if log_file.exist?
		exec(cmd)
	end
	return unless Process.wait2.last.exitstatus == 0

	ppid = Process.pid
	at_exit do
		stop_server(pid_file) if Process.pid == ppid
	end

	Timeout.timeout(6) do
		begin
			get test_url
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end
end

def stop_server(pid_file)
	pid_file = Pathname.new(pid_file)
	return unless pid_file.exist?

	#STDERR.puts HTTPClient.new.get_content("http://localhost:3100/stats")
	pid = pid_file.read.strip.to_i

	Timeout.timeout(20) do
		begin
			loop do
				Process.kill("TERM", pid)
				sleep 0.1
			end
		rescue Errno::ESRCH
			pid_file.unlink
		end
	end
end

