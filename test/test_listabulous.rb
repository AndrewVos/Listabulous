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
    user = create_user("email@address.com", "password01", "password01", "Jonny", "green")
    user.save
    user
  end

  def post_login(email = "email@address.com", password = "password01", remember = "off")
    post '/login', {:email => email, :password => password, :remember => remember}
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

    post_login("email@address.com", "invalid password")

    assert(last_response.body.include?("Login has failed"))
  end

  def test_post_login_encrypts_user_id_and_sets_cookie
    user = get_new_user

    encrypted = StringEncryption.new.encrypt(user._id.to_s)

    post_login
    follow_redirect!

    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted, last_request.cookies["user"])
  end

  def test_post_login_sets_non_persistent_cookie_when_remember_is_not_checked
    user = get_new_user
    post_login
    assert_no_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_post_login_sets_persistent_cookie_when_remember_is_checked
    user = get_new_user
    post_login("email@address.com", "password01", "on")
    assert_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_get_login_page_redirects_to_home_when_user_is_logged_in
    user = get_new_user

    post_login
    get '/login'

    assert(last_response.redirect?)
  end

  def test_get_register_returns_valid_body
    get '/register'
    assert(last_response.body.include?("Please create an account by entering your details below."))
  end
  
  def test_get_register_redirects_to_home_if_logged_in
    user = get_new_user

    post_login
    get '/register'

    assert(last_response.redirect?)
  end

  def test_post_register_with_different_passwords_displays_error  
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some other password" }
    assert(last_response.body.include?("Password doesn't match confirmation"))
  end

  def test_post_register_displays_error_when_user_is_not_saved
    post '/register', {:email => "this is not an email", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    assert(last_response.body.include?("Email is invalid"))
  end

  def test_post_register_creates_user
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    created_user = User.all.first
    assert_not_nil(created_user)
    assert_equal("email@address.com", created_user.email)
    assert_equal("Timmy", created_user.display_name)
    assert_equal(Digest::SHA1.hexdigest("some password"), created_user.password)
    assert_equal("#69D2E7", created_user.default_colour)
  end

  def test_post_register_encrypts_user_id_and_sets_cookie
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    follow_redirect!
    
    created_user = User.all.first
    
    encrypted = StringEncryption.new.encrypt(created_user._id.to_s)
    
    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted, last_request.cookies["user"])
  end
  
  def test_post_register_sets_non_persistent_cookie_when_remember_is_not_checked
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    assert_no_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])  
  end

  def test_post_register_sets_persistent_cookie_when_remember_is_checked
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password", :remember => "on" }
    assert_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_post_register_redirects_to_home_after_successful_account_creation
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    assert(last_response.redirect?)
  end

  def test_post_register_displays_error_when_email_already_exists    
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }

    assert(last_response.body.include?("Email has already been taken"))
  end

  def test_get_logout_clears_cookies
    user = get_new_user
    post_login
    
    get '/logout'
    assert(last_response.redirect?)
    get '/'
    assert_nil(last_request.cookies["user"])
  end

end