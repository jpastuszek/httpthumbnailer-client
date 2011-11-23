$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

require 'daemon'

def gem_dir
	Pathname.new(__FILE__).dirname + '..'
end

def spec_dir
	gem_dir + 'spec'
end

def server_start
	File.exist?("/tmp/httpthumbnailer.pid") and server_stop
	fork do 
		Daemon.daemonize("/tmp/httpthumbnailer.pid", spec_dir + 'server.log')
		exec("httpthumbnailer")
	end

	Timeout.timeout(10) do
		begin   
			server_get '/'
		rescue Errno::ECONNREFUSED
			sleep 0.1
			retry
		end
	end
end

def server_stop
	File.open("/tmp/httpthumbnailer.pid") do |pidf|
		pid = pidf.read

		Timeout.timeout(10) do
			begin   
				loop do 
					ret = Process.kill("TERM", pid.strip.to_i)
					sleep 0.1
				end
			rescue Errno::ESRCH
			end
		end
	end
end

def server_get(uri)
	HTTPClient.new.get_content("http://localhost:3100#{uri}")
end

