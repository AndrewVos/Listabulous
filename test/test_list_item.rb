require 'test/unit'
require 'mongo_mapper'

require 'test/unit'
require 'user'
require 'list_item'

class TestListItem < Test::Unit::TestCase

  def setup
    MongoMapper.database = "ListabulousTest"
    User.collection.remove
  end

  def test_does_not_save_when_text_is_empty
    user = create_user("email@address.com", "password1", "John Doe", "Pink")
    list_item = create_list_item(nil, "red", false)

    user.list_items << list_item
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(list_item.errors.on(:text))
  end

  def test_does_not_save_when_colour_is_empty
    user = create_user("email@address.com", "password1", "John Doe", "Pink")
    list_item = create_list_item("some text", nil, false)

    user.list_items << list_item
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(list_item.errors.on(:colour))
  end
  
  def test_does_not_save_when_complete_is_empty
    user = create_user("email@address.com", "password1", "John Doe", "Pink")
    list_item = create_list_item("some text", "red", nil)

    user.list_items << list_item
    assert_equal(false, user.save)
    assert_equal(1, user.errors.count)
    assert(list_item.errors.on(:complete))
  end

  def create_list_item(text, colour, complete)
    list_item = ListItem.new
    list_item.text = text
    list_item.colour = colour
    list_item.complete = complete
    list_item
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