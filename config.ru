require 'listabulous'

set :app_file, File.expand_path(File.dirname(__FILE__) + '/listabulous.rb')
set :public,   File.expand_path(File.dirname(__FILE__) + '/public')
set :views,    File.expand_path(File.dirname(__FILE__) + '/views')


run Sinatra::Application
