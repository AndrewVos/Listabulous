require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

$: << File.expand_path(File.join(File.dirname(__FILE__), "lib"))
require 'user'
require 'list_item'
require 'string_encryption'

enable :sessions


require 'uri'
configure :production do
  #mongodb://app274790:7832nmwusv7of7nqr71yzu@flame.mongohq.com:27035/app274790
  mongohq_url = ENV['MONGOHQ_URL']
  MongoMapper.connection = Mongo::Connection.from_uri(mongohq_url)
  MongoMapper.database = mongohq_url[mongohq_url.rindex("/") + 1, mongohq_url.length]
end
configure :development do
  MongoMapper.database = "Listabulous"
end

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
    persistent = params[:remember] == "on"
    set_user_cookie(response, user, persistent)
    redirect '/'
  end
end

get '/logout/?' do
  response.delete_cookie("user")
  redirect '/'
end

get '/register/?' do
  redirect '/' if @current_user != nil
  erb :register
end

post '/register/?' do
  user = User.new
  user.email = params[:email]
  user.display_name = params[:display_name]
  user.password = params[:password]
  user.password_confirmation = params[:password_confirmation]
  user.default_colour = "#69D2E7"

  user.list_items << ListItem.new(:text => "Try out Listabulous", :colour => "#69D2E7", :complete => true)
  user.list_items << ListItem.new(:text => "Click on an item to mark it as complete", :colour => "#69D2E7", :complete => false)
  user.list_items << ListItem.new(:text => "Click the coloured square on the left to change an items colour", :colour => "#69D2E7", :complete => false)
  user.list_items << ListItem.new(:text => "Items are sorted by their colour, and their text", :colour => "#69D2E7", :complete => false)
  user.list_items << ListItem.new(:text => "Click the cross on the right to delete an item", :colour => "#69D2E7", :complete => false)

  if user.save
    persistent = params[:remember] == "on"
    set_user_cookie(response, user, persistent)    
    redirect '/'
  else
    @account_creation_errors = user.errors.full_messages
    erb :register
  end
end

post '/api/set-user-default-colour/?' do
  default_colour = params[:default_colour]
  @current_user.default_colour = default_colour
  @current_user.save
end

post '/api/add-list-item/?' do
  text = params[:text]
  colour = params[:colour]

  list_item = ListItem.new(:text => text, :colour => colour, :complete => false)
  @current_user.list_items << list_item
  @current_user.save
  erb :list_item, :layout => false, :locals => { :list_item => list_item }
end

post '/api/delete-list-item/?' do
  id = params[:id]
  list_item = @current_user.list_items.find(id)
  @current_user.list_items.delete(list_item)
  @current_user.save
end

post '/api/set-list-item-colour/?' do
  id = params[:id]
  colour = params[:colour]
  
  list_item = @current_user.list_items.find(id)
  list_item.colour = colour
  @current_user.save
end

post '/api/mark-list-item-complete/?' do
  id = params[:id]
  complete = params[:complete]
  
  list_item = @current_user.list_items.find(id)
  list_item.complete = complete
  @current_user.save
end

def set_user_cookie(response, user, persistent)
  encrypted_cookie = StringEncryption.new.encrypt(user._id.to_s)

  if persistent
    response.set_cookie "user", {:value => encrypted_cookie, :expires => Time.now + 94608000}
  else
    response.set_cookie("user", encrypted_cookie)
  end
end