require 'spec_helper'
require 'spec_helper_methods'

describe "Listabulous" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before :each do
    User.collection.remove
  end

  def get_new_user
    user = create_user("email@address.com", "password01", "password01", "Jonny", "green")
    user.save
    user
  end

  def post_login(email = "email@address.com", password = "password01", remember = "off")
    post '/login', {:email => email, :password => password, :remember => remember}
  end

  def post_register_user
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
  end

  describe "GET /" do
    context "with the request url http://example.org/login" do
      it "redirects to the url with the www subdomain" do
        get "http://example.org/login"
        last_response.redirect?.should == true
        last_response.status.should == 301
      end
    end
    context "with the request url http://localhost/login" do
      it "does not redirect" do
        get 'http://localhost/login'
        last_response.ok?.should == true
        last_response.redirect?.should == false
      end
    end
    context "with an encrypted user id in the cookie encrypted with different key/iv to the env key" do
      before :each do
        old_key = ENV["COOKIE_ENCRYPTION_KEY"]
        old_iv = ENV["COOKIE_ENCRYPTION_IV"]
        ENV["COOKIE_ENCRYPTION_KEY"] = "r\036V\232bC\273\017\024HH_`p\b\221\307w\263\2115\036l\023\322\214\304na\200<\337"
        ENV["COOKIE_ENCRYPTION_IV"] = "\032\020\ae\263^\322\213\030\206v\350'u$\233"

        user = get_new_user
        post_login
        follow_redirect!

        ENV["COOKIE_ENCRYPTION_KEY"] = old_key
        ENV["COOKIE_ENCRYPTION_IV"] = old_iv
        get '/'
        get '/'
      end
      
      it "removes the cookie" do
        last_request.cookies["user"].should == nil
      end
      
      it "redirects to the login page" do
        last_response.redirect?.should == true
      end
    end
    
    context "with an encrypted user id in cookie that does not match a user" do
        before :each do
          user = get_new_user
          post_login
          follow_redirect!
          user.destroy
          get '/'
          get '/'
        end
        
        it "removes the cookie" do
          last_request.cookies["user"].should == nil
        end
        
        it "redirects to the login page" do
          last_response.redirect?.should == true
        end
    end
    
    context "with an unauthenticated user" do
      it "redirects to /login" do
        get '/'
        last_response.redirect?.should == true
        last_response.ok?.should == false
        last_response.location.should == "/login"
      end
    end
    
    context "with an authenticated user" do
      it "displays the users display name" do
        user = get_new_user
        post_login
        get '/'
        assert(last_response.body.include?("Jonny"))
      end
      
      it "renders the default palettes" do
        user = get_new_user
        post_login
        get '/'
        app.new do |erb_app|
          expected_response_body = erb_app.erb(:colour_picker, :layout => false, :locals => { :palettes => Palette.default_palettes })
          last_response.body.should include expected_response_body
        end
      end
    end
  end

  describe "GET /login" do
    context "with an unauthenticated user" do
      it "renders the login page" do
        get '/login'
        last_response.body.should include "Enter your email address and password to login."
      end
    end
    
    context "with an authenticated user" do
      it "redirects to home" do
        user = get_new_user
        post_login
        get '/login'
        last_response.redirect?.should == true
      end        
    end
  end

  describe "POST /login" do
    context "with empty login details" do
      it "tells the user that login has failed" do
        post '/login'
        last_response.body.should include "Login has failed"
      end
    end
    
    context "with an invalid email address" do
      before :each do
        user = get_new_user
        post_login("invalid.email@address.com")
      end

      it "tells the user that login has failed" do
        last_response.body.should include "Login has failed"
      end
    end
    
    context "with an invalid password" do
      before :each do
        user = get_new_user
        post_login("email@address.com", "invalid password")
      end

      it "tells the user that login has failed" do
        last_response.body.should include "Login has failed"
      end
    end
    
    context "with valid login details" do
      before :each do
        user = get_new_user
        post_login
        follow_redirect!
        get '/'
      end
      
      it "encrypts the user id and sets the 'user' cookie" do
        encrypted_id = StringEncryption.new.encrypt(User.first._id.to_s)

        last_request.cookies["user"].should_not == nil
        last_request.cookies["user"].should == encrypted_id
      end
    end
    
    context "with an upper case email address" do
      before :each do
        user = get_new_user
        post_login("EMAIL@ADDRESS.com")
        follow_redirect!
      end
      
      it "sets the 'user' cookie" do
        last_request.cookies["user"].should_not == nil
      end
    end
    
    context "with 'remember' not checked" do
      before :each do
        user = get_new_user
        post_login
      end
      
      it "sets a non persistent cookie" do
        last_response["Set-Cookie"].should_not match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
      end
    end
    
    context "with 'remember' checked" do
      before :each do
        user = get_new_user
        post_login("email@address.com", "password01", "on")
      end
      
      it "sets a persistent cookie" do
        last_response["Set-Cookie"].should match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
      end
    end
  end

  describe "GET /forgotten_password" do
    it "renders the forgotten password page" do
      get "/forgotten_password"
      last_response.body.should include "Enter your email address and click Send to send a password recovery email."
    end
  end

  describe "POST /forgotten_password" do
    before :each do
      Email.stub!(:send).with(any_args)
      ActiveSupport::SecureRandom.stub!(:hex).with(16)
    end

    context "with an email address that doesn't exist in the database" do
      it "shows an error" do
        post "/forgotten_password", {:email => "some.email.address@bla.com"}
        last_response.body.should include "An account with the specified email address does not exist."
      end
    end

    context "with a valid email address" do
      it "shows confirmation that the email has been sent" do
        user = get_new_user
        post "/forgotten_password", { :email => user.email }
        last_response.body.should include "An email has been sent to the email address that you specified."
      end

      it "sends an email to the specified email address" do
        user = get_new_user
        Email.should_receive(:send).with(user.email, anything, anything)
        post "/forgotten_password", { :email => user.email }
      end

      it "sends an email with a subject" do
        user =  get_new_user
        Email.should_receive(:send).with(anything, "Listabulous - Forgotten Password Email", anything)
        post "/forgotten_password", { :email => user.email }
      end

      it "generates a random key" do
        user = get_new_user
        ActiveSupport::SecureRandom.should_receive(:hex).with(16)
        post "/forgotten_password", { :email => user.email }
      end        

      it "saves the random key to the user" do
        user = get_new_user
        forgotten_password_key = "some really secure value"
        ActiveSupport::SecureRandom.stub!(:hex).with(16).and_return forgotten_password_key
        post "/forgotten_password", { :email => user.email }
        user.reload
        user.forgotten_password_key.should == forgotten_password_key        
      end

      it "sends an email containing the forgotten password url" do
        user = get_new_user
        forgotten_password_key = "some really secure value"
        ActiveSupport::SecureRandom.stub!(:hex).with(16).and_return forgotten_password_key
        Email.should_receive(:send) { |to, subject, body|
          body.should include "http://www.listabulous.co.uk/forgotten_password_change_password/?email=#{user.email}&key=#{forgotten_password_key}"
        }
        post "/forgotten_password", { :email => user.email }
      end

      it "sends an email using the forgotten password email template" do
        user = get_new_user
        forgotten_password_key = "some really secure value"
        ActiveSupport::SecureRandom.stub!(:hex).with(16).and_return forgotten_password_key

        app.new do |erb_app|
          expected_response_body = erb_app.erb :forgotten_password_email, :layout => false, :locals => { :email => user.email, :key => forgotten_password_key }
          Email.should_receive(:send).with(anything, anything, expected_response_body)
        end

        post "/forgotten_password", { :email => user.email }
      end
    end

    context "with an email address that is all in uppercase" do
      it "shows confirmation that the email has been sent" do
        user = get_new_user
        post "/forgotten_password", { :email => user.email.upcase }
        last_response.body.should include "An email has been sent to the email address that you specified."
      end
    end
  end

  describe "GET /register" do
    context "with an unauthenticated user" do
      it "renders the register page" do
        get '/register'
        last_response.body.should include "Please create an account by entering your details below."
      end
    end
    context "with an authenticated user" do
      it "redirects to home" do
        user = get_new_user
        post_login
        get '/register'
        last_response.redirect?.should == true
      end
    end
  end

  describe "POST /register" do
    context "with passwords that do not match" do
      it "displays a useful message" do
        post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some other password" }
        last_response.body.should include "Password doesn't match confirmation"
      end
    end
    
    context "with an invalid email address" do
      it "displays a useful message" do
        post '/register', {:email => "this is not an email", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
        last_response.body.should include "Email is invalid"
      end
    end
    
    context "with valid details" do
      it "creates a user" do
        post_register_user
        created_user = User.all.first

        created_user.should_not == nil
        created_user.email.should == "email@address.com"
        created_user.display_name.should == "Timmy"
        created_user.password.should == Digest::SHA1.hexdigest("some password")
        created_user.default_colour.should == "#69D2E7"
      end

      it "adds the default list items to the user" do
        post_register_user
        created_user = User.all.first

        created_user.list_items.count.should == 5

        created_user.list_items[0].text.should == "Try out Listabulous"
        created_user.list_items[1].text.should == "Click on an item to mark it as complete"
        created_user.list_items[2].text.should == "Click the coloured square on the left to change an items colour"
        created_user.list_items[3].text.should == "Items are sorted by their colour, and their text"
        created_user.list_items[4].text.should == "Click the cross on the right to delete an item"

        created_user.list_items[0].colour.should == "#69D2E7"
        created_user.list_items[1].colour.should == "#69D2E7"
        created_user.list_items[2].colour.should == "#69D2E7"
        created_user.list_items[3].colour.should == "#69D2E7"
        created_user.list_items[4].colour.should == "#69D2E7"

        created_user.list_items[0].complete.should == true
        created_user.list_items[1].complete.should == false
        created_user.list_items[2].complete.should == false
        created_user.list_items[3].complete.should == false
        created_user.list_items[4].complete.should == false
      end

      it "encrypts the user id and sets the cookie" do
        post_register_user
        follow_redirect!

        created_user = User.all.first

        encrypted = StringEncryption.new.encrypt(created_user._id.to_s)

        last_request.cookies["user"].should_not == nil
        last_request.cookies["user"].should == encrypted
      end

      context "with 'remember' checked" do
        it "sets a persistent cookie" do
          post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password", :remember => "on" }
          last_response["Set-Cookie"].should match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
        end
      end

      context "with 'remember' not checked" do
        it "does not set a persistent cookie" do
          post_register_user
          last_response["Set-Cookie"].should_not match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
        end
      end

      it "redirects to home" do
        post_register_user
        last_response.redirect?.should == true
      end

      context "with an email address that already exists" do
        it "displays a useful error" do
          post_register_user
          post_register_user
          last_response.body.should include "Email has already been taken"
        end
      end
    end
  end

  describe "GET /logout" do
    it "deletes the user cookie" do
      user = get_new_user
      post_login

      get '/logout'
      last_response.redirect?.should == true
      follow_redirect!
      last_request.cookies["user"].should == nil
    end
  end

  describe "GET /forgotten_password_change_password" do
    it "renders the forgotten_password_change_password page" do
      get '/forgotten_password_change_password'
      last_response.body.should include "Enter your new password below."
    end
  end

  describe "POST /forgotten_password_change_password" do
    context "with a valid email address and key" do
      before :each do
        @user = get_new_user
        @user.forgotten_password_key = "forgotten-password-key-42"
        @user.save

        @new_password = "kittehs!"
        post "/forgotten_password_change_password/?email=#{@user.email}&key=#{@user.forgotten_password_key}", { :password => @new_password, :password_confirmation => @new_password }
        @user.reload
      end

      it "updates the users password" do
        @user.password.should == Digest::SHA1.hexdigest(@new_password)        
      end

      it "does not display an error" do
        last_response.body.should_not include "There was an error updating your password"
      end

      it "displays a success message" do
        last_response.body.should include "Your password has been updated. Click <a href=\"/login\">here</a> to login."
      end
      
      it "removes the users forgotten password key" do
        @user.forgotten_password_key.should == nil
      end
    end

    context "with an invalid email address" do
      before :each do
        @user = get_new_user
        @user.forgotten_password_key = "forgotten-password-key-42"
        @user.save

        @new_password = "kittehs!"
        post "/forgotten_password_change_password/?email=invalid.email.address@domain.com&key=#{@user.forgotten_password_key}", { :password => @new_password, :password_confirmation => @new_password }
        @user.reload
      end

      it "displays an error" do
        last_response.body.should include "There was an error updating your password"
      end

      it "does not update the users password" do
        @user.password.should_not == Digest::SHA1.hexdigest(@new_password)
      end

      it "does not display a success message" do
        last_response.body.should_not include "Your password has been updated."
      end
    end

    context "with an invalid key" do
      before :each do
        @user = get_new_user
        @user.forgotten_password_key = "forgotten-password-key-42"
        @user.save

        @new_password = "kittehs!"
        post "/forgotten_password_change_password/?email=#{@user.email}&key=this_isnt_my_key", { :password => @new_password, :password_confirmation => @new_password }
        @user.reload
      end

      it "displays an error" do
        last_response.body.should include "There was an error updating your password"
      end

      it "does not update the users password" do
        @user.password.should_not == Digest::SHA1.hexdigest(@new_password)
      end
    end

    context "with different passwords" do
      before :each do
        @user = get_new_user
        @user.forgotten_password_key = "forgotten-password-key-42"
        @user.save

        @new_password = "kittehs!"
        post "/forgotten_password_change_password/?email=#{@user.email}&key=#{@user.forgotten_password_key}", { :password => @new_password, :password_confirmation => "A different password. Scandalous!" }
        @user.reload
      end

      it "displays an error" do
        last_response.body.should include "There was an error updating your password"
      end

      it "does not update the users password" do
        @user.password.should_not == Digest::SHA1.hexdigest(@new_password)
      end
    end
  end

  describe "GET /statistics" do
    it "renders the statistics page" do
      get '/statistics'
      last_response.body.should include '<legend>Statistics</legend>'
    end

    it "displays the user count" do
      1.upto 11 do |number|
        user = create_user("email#{number}@address.com", "password01", "password01", "Jonny", "green")
        user.save
      end

      get '/statistics'
      assert(last_response.body.include?('Users: 11'))
    end
  end

  describe "POST /api/set-user-default-colour" do
    it "sets the users default colour" do
      user = get_new_user
      post_login
      post '/api/set-user-default-colour', { :default_colour => "Fuchsia"}
      user.reload
      user.default_colour.should == "Fuchsia"
    end
  end

  describe "POST /api/add-list-item" do
    it "adds the item" do
      user = get_new_user
      post_login

      text = "This is my new list item!"
      colour = "black as my soul"
      post '/api/add-list-item', { :text => text, :colour => colour }

      user.reload
      list_item = user.list_items.first
      user.list_items.count.should == 1
      list_item.text.should == text
      list_item.colour.should == colour
    end

    it "returns the html for the new list item" do
      user = get_new_user
      post_login

      text = "This is my new list item!"
      colour = "black as my soul"
      post '/api/add-list-item', { :text => text, :colour => colour }
      user.reload

      app.new do |erb_app|
        expected_response_body = erb_app.erb :list_item, :layout => false, :locals => { :list_item => user.list_items.first }
        last_response.body.should == expected_response_body
      end
    end
  end

  describe "POST /api/delete-list-item" do
    it "deletes the list item" do
      user = get_new_user
      post_login

      text = "This is my new list item!"
      colour = "black as my soul"
      user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
      user.save

      post '/api/delete-list-item', { :id => user.list_items.first._id.to_s }
      user.reload
      user.list_items.count.should == 0
    end
  end

  describe "POST /api/set-list-item-colour" do
    it "sets the list items colour" do
      user = get_new_user
      post_login

      text = "This is my new list item!"
      colour = "black as my soul"
      user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
      user.save

      post '/api/set-list-item-colour', { :id => user.list_items.first._id.to_s, :colour => "white"}
      user.reload
      user.list_items.first.colour.should == "white"
    end
  end

  describe "POST /api/mark-list-item-complete" do
    it "marks the list item complete" do
      user = get_new_user
      post_login

      text = "This is my new list item!"
      colour = "black as my soul"
      user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
      user.save

      post '/api/mark-list-item-complete', { :id => user.list_items.first._id.to_s, :complete => true}
      user.reload
      user.list_items.first.complete.should == true
    end
  end
end