$: << File.expand_path(File.join(File.dirname(__FILE__), "lib"))

require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

require 'user'
require 'list_item'
require 'palette'
require 'string_encryption'
require 'configure'

before do
  redirect_to_www!
  load_user_from_cookie
end

def redirect_to_www!
  if request.host != "localhost"
    expected_url_start = "http://www."
    if request.url[0, expected_url_start.length] != expected_url_start
      redirect request.url.sub("http://", "http://www."), 301
    end
  end
end

def load_user_from_cookie
  encrypted_user_id = request.cookies["user"]
  if encrypted_user_id != nil
    begin
      user_id = StringEncryption.new.decrypt(encrypted_user_id)
    rescue
      delete_user_cookie!
    end
    
    if user_id != nil
      @current_user = User.find(user_id)
      if @current_user == nil
        delete_user_cookie!
      end
    end
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
  if params[:forgotten_password_email] != nil
    forgotten_password_email = params[:forgotten_password_email]
    forgotten_password_email.downcase!
    user_account = User.all(:email => forgotten_password_email).first
    
    @forgotten_password_failed = user_account == nil
    @forgotten_password_succeeded = user_account != nil
    
    if user_account != nil
    end
  end
  
  if params[:email] != nil && params[:password] != nil
    email = params[:email]
    email.downcase!

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
  delete_user_cookie!
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

get '/statistics/?' do
  erb :statistics, :locals => { :users => User.all.count }
end

def set_user_cookie(response, user, persistent)
  encrypted_cookie = StringEncryption.new.encrypt(user._id.to_s)

  if persistent
    response.set_cookie "user", {:value => encrypted_cookie, :expires => Time.now + 94608000}
  else
    response.set_cookie "user", {:value => encrypted_cookie}
  end
end

def delete_user_cookie!
  response.delete_cookie "user"
end