require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

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
  if params[:email] != nil && params[:password] != nil
    email = params[:email]
    hashed_password = Digest::SHA1.hexdigest(params[:password])
    user_results = User.all(:email => email, :password => hashed_password)
    user = user_results.first
  end

  if user == nil
    @login_failed = true
    erb :login
  else

    encrypted_cookie = StringEncryption.new.encrypt(user._id.to_s + user.email + user.password)
    response.set_cookie("user", encrypted_cookie)
  end
end

get '/register/?' do
  erb :register
end