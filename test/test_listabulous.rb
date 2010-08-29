require 'test_helper'

class TestListabulous < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    MongoMapper.database = "ListabulousTest"
    User.collection.remove
  end

  def app
    Sinatra::Application
  end

  def get_new_user
    user = create_user("email@address.com", "password01", "Jonny", "green")
    user.save
    user
  end

  def post_login(email = "email@address.com", password = "password01")
    post '/login', {:email => email, :password => password}
  end

  def test_get_home_redirects_to_login_page_when_not_logged_in
    get '/'
    assert(last_response.redirect?)
  end

  def test_get_home_shows_display_name_when_logged_in
    user = get_new_user

    post_login
    follow_redirect!

    assert(last_response.body.include?("Jonny"))
  end

  def test_get_login_returns_expected_body
    get '/login'
    assert(last_response.body.include?("Enter your email address and password to login."))
  end

  def test_post_login_returns_login_page_when_user_credentials_are_empty
    post '/login'
    assert(last_response.body.include?("Login has failed"))
  end

  def test_post_login_returns_login_page_when_email_is_invalid
    user = get_new_user

    post_login("invalid.email@address.com")

    assert(last_response.body.include?("Login has failed"))
  end

  def test_post_login_returns_login_page_when_password_is_invalid
    user = get_new_user

    post_login(nil,"invalid password")

    assert(last_response.body.include?("Login has failed"))
  end

  def test_post_login_encrypts_user_id_sets_cookie_and_redirects
    user = get_new_user

    encrypted = StringEncryption.new.encrypt(user._id.to_s)

    post_login
    assert(last_response.redirect?)
    follow_redirect!

    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted, last_request.cookies["user"])
  end

  def test_get_register_returns_valid_body
    get '/register'
    assert(last_response.body.include?("Please create an account by entering your details below."))
  end

  def test_get_login_page_redirects_to_home_when_user_is_logged_in
    user = get_new_user

    post_login
    get '/login'

    assert(last_response.redirect?)
  end

end