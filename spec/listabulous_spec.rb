require 'spec_helper'

describe "Listabulous" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should redirect to /login" do
    get '/'
    last_response.redirect?.should == true
    last_response.ok?.should == false
    follow_redirect!
    last_response.location.should == "/login"
  end
end