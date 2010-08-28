require 'test_helper'

set :environment, :test

class TestListabulous < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    MongoMapper.database = "ListabulousTest"
    User.collection.remove
  end

  def app
    Sinatra::Application
  end

  def test_get_index_exists
    get '/'
    assert(last_response.ok?)
  end

  def test_get_login_exists
    get '/login'
    assert(last_response.ok?)
    get '/login/'
    assert(last_response.ok?)
  end

  def test_get_login_returns_expected_body
    get '/login'
    assert(last_response.body.include?("Enter your email address and password to login."))
  end

  def test_post_login_exists
    post '/login'
    assert(last_response.ok?)
  end

  def test_post_login_returns_login_page_when_user_credentials_are_wrong
    post '/login'
    assert(last_response.ok?)
    assert(last_response.body.include?("Login has failed"))
  end

  def test_post_login_encrypts_id_and_email_and_hashed_password_and_then_sets_cookie
    user = create_user("email@address.com", "password01", "Johhny", "green")
    user.save
    
    encrypted = StringEncryption.new.encrypt(user._id.to_s + user.email + user.password)

    post '/login', {:email => "email@address.com", :password => "password01"}    
    get '/'
    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted, last_request.cookies["user"])
  end

  def test_get_register_exists
    get '/register'
    assert(last_response.ok?)
    get '/register/'
    assert(last_response.ok?)
  end

  def test_get_register_returns_valid_body
    get '/register'
    assert(last_response.body.include?("Please create an account by entering your details below."))
  end

end