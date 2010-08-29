require 'test_helper'

class TestUser < Test::Unit::TestCase

  def setup
    MongoMapper.database = "ListabulousTest"
    User.collection.remove    
  end

  def test_does_not_save_when_email_is_empty
    user = create_user(nil, "thepassword", "thepassword", "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:email))
  end

  def test_does_not_save_when_email_is_invalid
    user = create_user("not a valid email!", "thepassword", "thepassword", "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:email))
  end

  def test_does_not_save_when_password_is_empty
    user = create_user("email@address.com", nil, nil, "John", "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:password))
  end

  def test_does_not_save_when_display_name_is_empty
    user = create_user("email@address.com", "password", "password", nil, "Red")

    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:display_name))
  end
  
  def test_does_not_save_when_default_colour_is_empty
    user = create_user("email@address.com", "password", "password", "John Doe", nil)
    
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:default_colour))
  end
  
  def test_does_not_save_when_email_is_not_unique
    first_user = create_user("email@address.com", "password1", "password1", "John Doe", "red")
    assert_equal(true, first_user.save)
    
    second_user = create_user("email@address.com", "password2", "password2", "John Doe", "red")    
    assert_equal(false, second_user.save)
    assert_equal(1, second_user.errors.count)
    assert(second_user.errors.on(:email))
  end
  
  def test_password_is_hashed_when_saving
    user = create_user("email@address.com", "some password","some password", "John Doe", "red")
    user.save
    sha1 = Digest::SHA1.hexdigest("some password")
    assert_equal(sha1, user.password)
  end
  
  def test_password_is_only_hashed_on_the_first_save
    user = create_user("email@address.com", "some password", "some password", "John Doe", "red")
    user.save
    sha1 = Digest::SHA1.hexdigest("some password")
    user.save
    assert_equal(sha1, user.password)
  end
  
  def test_does_not_save_when_passwords_are_different
    user = create_user("email@address.com", "password", "different password", "John Doe", "red")
    
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(user.errors.on(:password))
  end
  
  def test_does_not_commit_password_confirmation_to_database
    user = create_user("email@address.com", "password", "password", "John Doe", "red")
    user.save
    saved_user = User.all.first
    assert_nil(saved_user.password_confirmation)
  end
  
end