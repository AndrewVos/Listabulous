require "test/unit"
require "models/user"

class TestUser < Test::Unit::TestCase
  
  def test_throws_when_no_email_specified
    user = User.new({ :email => nil})
puts user.email
    user.save
  end
  
end