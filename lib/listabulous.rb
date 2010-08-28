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
  puts params[:email]
  puts params[:password]
  puts params[:remember]
end

get '/register/?' do
end