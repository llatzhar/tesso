require 'tesso'

# http://blog.s21g.com/articles/1638
configure :development do
  class Sinatra::Reloader < Rack::Reloader
    def safe_load(file, mtime, stderr = $stderr)
      ::Sinatra::Application.reset!
      use_in_file_templates! file
      stderr.puts "#{self.class}: reseting routes"
      super
    end
  end
  use Sinatra::Reloader
end

run Sinatra::Application
