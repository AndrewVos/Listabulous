require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

require 'lib/string_encryption'

enable :sessions

before do
  encrypted_user_id = request.cookies["user"]
  if encrypted_user_id != nil
    user_id = StringEncryption.new.decrypt(encrypted_user_id)
    @current_user = User.find(user_id)
  end
end

get '/' do
  redirect '/login' if @current_user == nil
  erb :index
end

get '/login/?' do
  redirect '/' if @current_user != nil
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
    encrypted_cookie = StringEncryption.new.encrypt(user._id.to_s)
    response.set_cookie("user", encrypted_cookie)
    redirect '/'
  end
end

get '/register/?' do
  erb :register
end