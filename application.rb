require 'rubygems'
require 'sinatra'
require 'configuration'

get '/' do
  erb :index
end