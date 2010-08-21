require 'test/unit'
require 'rr'
require 'sinatra'
require 'rack/test'
set :environment, :test
require 'configuration'

require 'authentication'


class TestAuthentication < Test::Unit::TestCase
  include Rack::Test::Methods
  include RR::Adapters::TestUnit

  def app
    Sinatra::Application
  end

  def test_login_sets_session_id_cookie
    cookies = {}
    authentication = Authentication.new(cookies)
    authentication.login("Benjamin Franklin")
    assert_not_nil(cookies[:session_id])
  end
  
  def test_login_adds_encrypted_username_to_cookies
    cookies = {}
    authentication = Authentication.new(cookies)
    authentication.login("Benjamin Franklin")
    assert_not_equal("Benjamin Franklin", cookies[:session_id])
  end

  def test_current_user_returns_nil_when_cookies_do_not_contain_session_id
    cookies = {}
    authentication = Authentication.new(cookies)
    assert_nil(authentication.current_user)
  end
  
  def test_current_user_returns_username
    username = "John Doe"
    cookies = {}
    authentication = Authentication.new(cookies)
    authentication.login(username)
    assert_equal(username, authentication.current_user)
  end
  
  def test_logout_removes_session_id_from_cookies
    cookies = { :session_id => "Some name" }
    authentication = Authentication.new(cookies)
    authentication.logout
    assert_nil(cookies[:session_id])
  end
  
end