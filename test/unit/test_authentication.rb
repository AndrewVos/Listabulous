require 'test/unit'
require 'authentication'
require 'mocha'
require 'rack/test'

set :environment, :test

class TestAuthentication < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def setup
   # request = mock("request")
  #  response = mock("response", :body= => nil)
  #  route_params = mock("route_params")
   # @event_context = Sinatra::EventContext.new(request, response, route_params)
    
  end
  def test_login_sets_cookie
    
  end
end