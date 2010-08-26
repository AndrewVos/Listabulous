require 'test_helper'
require 'models/user'

class TestUser < Test::Unit::TestCase

  def test_does_not_save_when_email_is_empty
    user = create_user(nil, "thepassword", "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:email))
  end

  def test_does_not_save_when_email_is_invalid
    user = create_user("not a valid email!", "thepassword", "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:email))
  end

  def test_does_not_save_when_password_is_empty
    user = create_user("email@address.com", nil, "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:password))
  end

  def test_does_not_save_when_display_name_is_empty
    user = create_user("email@address.com", "password", nil, "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:display_name))
  end
  
  def test_does_not_save_when_default_colour_is_empty
    user = create_user("email@address.com", "password", "John Doe", nil)
    
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:default_colour))
  end
  
  def create_user(email, password, display_name, default_colour)
    user = User.new
   
    user.email = email
    user.password = password
    user.display_name = display_name
    user.default_colour = default_colour
    
    user
  end
end