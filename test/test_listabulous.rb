require 'test/unit'
require 'rack/test'

require 'listabulous'

set :environment, :test

class TestListabulous < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def test_case_name
    get '/'
    assert(last_response.ok?)
  end
  
end