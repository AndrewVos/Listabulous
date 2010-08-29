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

    if params[:remember] == "on"
      response.set_cookie "user", {:value => encrypted_cookie, :expires => Time.now + 94608000}
    else
      response.set_cookie("user", encrypted_cookie)
    end

    redirect '/'
  end
end

get '/register/?' do
  erb :register
end

post '/register/?' do
  user = User.new
  user.email = params[:email]
  user.display_name = params[:display_name]
  user.password = params[:password]
  user.password_confirmation = params[:password_confirmation]
  user.default_colour = "#69D2E7"

  if user.save
    redirect '/'
  else
    @account_creation_errors = user.errors.full_messages
    erb :register
  end
end