require 'spec_helper'
require 'spec_helper_methods'

Spec::Runner.configure do |conf|
  conf.include Rack::Test::Methods
end

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

    it "should render the login page" do
      get '/login'
      last_response.body.should include "Enter your email address and password to login."
    end

    context "posting login details" do
      context "login details are empty" do
        it "should tell the user that login has failed" do
          post '/login'
          last_response.body.should include "Login has failed"
        end
      end
      context "login details contain invalid email address" do
        before :each do
          user = get_new_user
          post_login("invalid.email@address.com")
        end
        
        it "should tell the user that login has failed" do
          last_response.body.should include "Login has failed"
        end
      end
      context "login details contain invalid password" do
        before :each do
          user = get_new_user
          post_login("email@address.com", "invalid password")
        end
        
        it "should tell the user that login has failed" do
          last_response.body.should include "Login has failed"
        end
      end
      context "login details are valid" do
        before :each do
          user = get_new_user
          post_login
          follow_redirect!
          get '/'
        end
        it "should encrypt the user id and set the cookie" do
          encrypted_id = StringEncryption.new.encrypt(User.first._id.to_s)

          last_request.cookies["user"].should_not == nil
          last_request.cookies["user"].should == encrypted_id
        end
      end
    end
  end

  context "request path does not have www subdomain" do
    context "http://example.org/login" do
      it "should redirect to the url with the www subdomain" do
        get "http://example.org/login"
        last_response.redirect?.should == true
        last_response.status.should == 301
      end
    end
    context "http://localhost/login" do
      it "should not redirect" do
        get 'http://localhost/login'
        last_response.ok?.should == true
        last_response.redirect?.should == false
      end
    end
  end

  context "authenticated user" do
    before :each do
      user = get_new_user
      post_login
    end

    it "should display the users display name" do
      get '/'
      assert(last_response.body.include?("Jonny"))
    end

    it "should render the default palettes" do
      get '/'
      app.new do |erb_app|
        expected_response_body = erb_app.erb(:colour_picker, :layout => false, :locals => { :palettes => Palette.default_palettes })
        last_response.body.should include expected_response_body
      end
    end    
  end

end