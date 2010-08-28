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
  
  def test_post_login_exists
    post '/login'
    assert(last_response.ok?)
  end
  
  def test_get_register_exists
    get '/register'
    assert(last_response.ok?)
    get '/register/'
    assert(last_response.ok?)
  end
  
end