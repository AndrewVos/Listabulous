require 'rubygems'
require 'sinatra'
require 'configuration'

get '/' do
  erb :index
end

get '/login/?' do
  erb :login
end

post '/login/?' do  
  @login_failed = true
  erb :login
end

get '/register/?' do
  erb :register
end