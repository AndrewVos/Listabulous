require 'rubygems'
require 'sinatra'
require 'configuration'
require 'lib/string_encryption'

enable :sessions

get '/' do
  erb :index
end

get '/login/?' do
  erb :login
end

post '/login/?' do
  #email = params[:email]
  #password = params[:password]
  
  
  @login_failed = true
  erb :login
end

get '/register/?' do
  erb :register
end