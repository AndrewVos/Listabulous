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
    context "request path does not have www subdomain" do
      context "request url is http://example.org/login" do
        it "should redirect to the url with the www subdomain" do
          get "http://example.org/login"
          last_response.redirect?.should == true
          last_response.status.should == 301
        end
      end
      context "request url is http://localhost/login" do
        it "should not redirect" do
          get 'http://localhost/login'
          last_response.ok?.should == true
          last_response.redirect?.should == false
        end
      end
    end
    context "encrypted user id in cookie encrypted with different key/iv" do
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
      it "should remove the cookie" do
        last_request.cookies["user"].should == nil
      end
      it "should redirect to the login page" do
        last_response.redirect?.should == true
      end
    end
    context "encrypted user value in cookie" do
      context "user has been deleted" do
        before :each do
          user = get_new_user
          post_login
          follow_redirect!
          user.destroy
          get '/'
          get '/'
        end
        it "should remove the cookie" do
          last_request.cookies["user"].should == nil
        end
        it "should redirect to the login page" do
          last_response.redirect?.should == true
        end
      end
    end
    context "unauthenticated user" do
      it "should redirect to /login" do
        get '/'
        last_response.redirect?.should == true
        last_response.ok?.should == false
        last_response.location.should == "/login"
      end
    end
    context "authenticated user" do
      it "should display the users display name" do
        user = get_new_user
        post_login
        get '/'
        assert(last_response.body.include?("Jonny"))
      end
      it "should render the default palettes" do
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
    context "unauthenticated user" do
      it "should render the login page" do
        get '/login'
        last_response.body.should include "Enter your email address and password to login."
      end
    end
    context "authenticated user" do
      it "should redirect to home" do
        user = get_new_user
        post_login
        get '/login'
        last_response.redirect?.should == true
      end        
    end
  end

  describe "POST /login" do
    context "empty login details" do
      it "should tell the user that login has failed" do
        post '/login'
        last_response.body.should include "Login has failed"
      end
    end
    context "invalid email address" do
      before :each do
        user = get_new_user
        post_login("invalid.email@address.com")
      end

      it "should tell the user that login has failed" do
        last_response.body.should include "Login has failed"
      end
    end
    context "invalid password" do
      before :each do
        user = get_new_user
        post_login("email@address.com", "invalid password")
      end

      it "should tell the user that login has failed" do
        last_response.body.should include "Login has failed"
      end
    end
    context "valid login details" do
      before :each do
        user = get_new_user
        post_login
        follow_redirect!
        get '/'
      end
      it "should encrypt the user id and set the 'user' cookie" do
        encrypted_id = StringEncryption.new.encrypt(User.first._id.to_s)

        last_request.cookies["user"].should_not == nil
        last_request.cookies["user"].should == encrypted_id
      end
    end
    context "upper case email address" do
      before :each do
        user = get_new_user
        post_login("EMAIL@ADDRESS.com")
        follow_redirect!
      end
      it "should set the 'user' cookie" do
        last_request.cookies["user"].should_not == nil
      end
    end
    context "'remember' is unchecked" do
      before :each do
        user = get_new_user
        post_login
      end
      it "should set a non persistent cookie" do
        last_response["Set-Cookie"].should_not match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
      end
    end
    context "'remember' is checked" do
      before :each do
        user = get_new_user
        post_login("email@address.com", "password01", "on")
      end
      it "should set a persistent cookie" do
        last_response["Set-Cookie"].should match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
      end
    end
    context "forgotten password email parameter is posted" do
      before :each do
        Email.stub!(:send).with(any_args)
        ActiveSupport::SecureRandom.stub!(:hex).with(16)
      end

      context "the email address doesn't exist in the database" do
        it "should show an error" do
          post "/login", {:forgotten_password_email => "some.email.address@bla.com"}
          last_response.body.should include "An account with the specified email address does not exist."
        end
      end
      context "the email address exists" do
        it "should show confirmation that the email has been sent" do
          user = get_new_user
          post "/login", { :forgotten_password_email => user.email }
          last_response.body.should include "An email has been sent to the email address that you specified."
        end

        it "sends an email to the specified email address" do
          user = get_new_user
          Email.should_receive(:send).with(user.email, anything, anything)
          post "/login", { :forgotten_password_email => user.email }
        end

        it "sends an email with a subject" do
          user =  get_new_user
          Email.should_receive(:send).with(anything, "Listabulous - Forgotten Password Email", anything)
          post "/login", { :forgotten_password_email => user.email }
        end

        it "should generate a random key" do
          user = get_new_user
          ActiveSupport::SecureRandom.should_receive(:hex).with(16)
          post "/login", { :forgotten_password_email => user.email }
        end        
        it "sends an email containing the forgotten password url" do
          user = get_new_user
          forgotten_password_key = "some really secure value"
          ActiveSupport::SecureRandom.stub!(:hex).with(16).and_return forgotten_password_key
          Email.should_receive(:send) { |to, subject, body|
            body.should include "http://www.listabulous.co.uk/change-password/?email=#{user.email}&key=#{forgotten_password_key}"
          }
          post "/login", { :forgotten_password_email => user.email }
        end
        it "sends an email using the forgotten password email template" do
          user = get_new_user
          forgotten_password_key = "some really secure value"
          ActiveSupport::SecureRandom.stub!(:hex).with(16).and_return forgotten_password_key

          app.new do |erb_app|
            expected_response_body = erb_app.erb :forgotten_password_email, :layout => false, :locals => { :email => user.email, :key => forgotten_password_key }
            Email.should_receive(:send).with(anything, anything, expected_response_body)
          end
          
          post "/login", { :forgotten_password_email => user.email }
        end
      end
      context "the email address is all in uppercase" do
        it "should show confirmation that the email has been sent" do
          user = get_new_user
          post "/login", { :forgotten_password_email => user.email.upcase }
          last_response.body.should include "An email has been sent to the email address that you specified."
        end
      end
    end
  end

  describe "GET /register" do
    context "unauthenticated user" do
      it "should render the register page" do
        get '/register'
        last_response.body.should include "Please create an account by entering your details below."
      end
    end
    context "authenticated user" do
      it "should redirect to home" do
        user = get_new_user
        post_login
        get '/register'
        last_response.redirect?.should == true
      end
    end
  end

  describe "POST /register" do
    context "password does not match password confirmation" do
      it "should display a useful message" do
        post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some other password" }
        last_response.body.should include "Password doesn't match confirmation"
      end
    end
    context "email is invalid" do
      it "should display a useful message" do
        post '/register', {:email => "this is not an email", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
        last_response.body.should include "Email is invalid"
      end
    end
    context "details are valid" do
      it "should create a user" do
        post_register_user
        created_user = User.all.first

        created_user.should_not == nil
        created_user.email.should == "email@address.com"
        created_user.display_name.should == "Timmy"
        created_user.password.should == Digest::SHA1.hexdigest("some password")
        created_user.default_colour.should == "#69D2E7"
      end
      it "should add the default list items to the user" do
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
      it "should encrypt the user id and set the cookie" do
        post_register_user
        follow_redirect!

        created_user = User.all.first

        encrypted = StringEncryption.new.encrypt(created_user._id.to_s)

        last_request.cookies["user"].should_not == nil
        last_request.cookies["user"].should == encrypted
      end
      context "'remember' is checked" do
        it "should set a persistent cookie" do
          post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password", :remember => "on" }
          last_response["Set-Cookie"].should match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
        end
      end
      context "'remember' is unchecked" do
        it "should not set a persistent cookie" do
          post_register_user
          last_response["Set-Cookie"].should_not match /expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../
        end
      end
      it "should redirect to home" do
        post_register_user
        last_response.redirect?.should == true
      end
      context "email address already exists" do
        it "should display a useful error" do
          post_register_user
          post_register_user
          last_response.body.should include "Email has already been taken"
        end
      end
    end

    describe "GET /logout" do
      it "should delete the user cookie" do
        user = get_new_user
        post_login

        get '/logout'
        last_response.redirect?.should == true
        follow_redirect!
        last_request.cookies["user"].should == nil
      end
    end

    describe "GET /statistics" do
      it "should render the statistics page" do
        get '/statistics'
        last_response.body.should include '<legend>Statistics</legend>'
      end

      it "should display the user count" do
        1.upto 11 do |number|
          user = create_user("email#{number}@address.com", "password01", "password01", "Jonny", "green")
          user.save
        end

        get '/statistics'
        assert(last_response.body.include?('Users: 11'))
      end
    end

    describe "POST /api/set-user-default-colour" do
      it "should set the users default colour" do
        user = get_new_user
        post_login
        post '/api/set-user-default-colour', { :default_colour => "Fuchsia"}
        user.reload
        user.default_colour.should == "Fuchsia"
      end
    end

    describe "POST /api/add-list-item" do
      it "should add the item" do
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

      it "should return the html for the new list item" do
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
      it "should delete the list item" do
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
      it "should set the list items colour" do
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
      it "should mark the list item complete" do
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
end