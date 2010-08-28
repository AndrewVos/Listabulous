require 'test/unit'
require 'rack/test'

require 'listabulous'

set :environment, :test

class TestListabulous < Test::Unit::TestCase
  include Rack::Test::Methods
  
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
  
  def test_post_login_sets_cookie
    post '/login'
    #assert_equal(1, last_request.cookies.count)
    
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