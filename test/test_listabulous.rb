require 'test_helper_methods'
require 'rack/test'
require 'listabulous'
require 'palette'

module Rack
  module Test
    DEFAULT_HOST = "www.example.org"  
  end
end

class TestListabulous < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup    
    MongoMapper.database = "ListabulousTest"
    User.collection.remove
  end

  def app
    Sinatra::Application
  end

  def get_new_user
    user = create_user("email@address.com", "password01", "password01", "Jonny", "green")
    user.save
    user
  end

  def post_login(email = "email@address.com", password = "password01", remember = "off")
    post '/login', {:email => email, :password => password, :remember => remember}
  end

  def post_register_user
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
  end
  
  def test_post_login_encrypts_user_id_and_sets_cookie
    user = get_new_user
    encrypted_id = StringEncryption.new.encrypt(user._id.to_s)

    post_login
    follow_redirect!

    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted_id, last_request.cookies["user"])
  end

  def test_post_login_sets_cookie_when_email_address_is_different_case
    user = get_new_user
    post_login("EMAIL@ADDRESS.com")

    assert(last_response.redirect?)
    follow_redirect!
    assert_not_nil(last_request.cookies["user"])  
  end

  def test_post_login_sets_non_persistent_cookie_when_remember_is_not_checked
    user = get_new_user
    post_login
    assert_no_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_post_login_sets_persistent_cookie_when_remember_is_checked
    user = get_new_user
    post_login("email@address.com", "password01", "on")
    assert_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_get_login_page_redirects_to_home_when_user_is_logged_in
    user = get_new_user

    post_login
    get '/login'

    assert(last_response.redirect?)
  end

  def test_get_register_returns_valid_body
    get '/register'
    assert(last_response.body.include?("Please create an account by entering your details below."))
  end

  def test_get_register_redirects_to_home_if_logged_in
    user = get_new_user

    post_login
    get '/register'

    assert(last_response.redirect?)
  end

  def test_post_register_with_different_passwords_displays_error  
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some other password" }
    assert(last_response.body.include?("Password doesn't match confirmation"))
  end

  def test_post_register_displays_error_when_user_is_not_saved
    post '/register', {:email => "this is not an email", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password" }
    assert(last_response.body.include?("Email is invalid"))
  end

  def test_post_register_creates_user
    post_register_user
    created_user = User.all.first
    assert_not_nil(created_user)
    assert_equal("email@address.com", created_user.email)
    assert_equal("Timmy", created_user.display_name)
    assert_equal(Digest::SHA1.hexdigest("some password"), created_user.password)
    assert_equal("#69D2E7", created_user.default_colour)
  end

  def test_post_register_creates_user_and_adds_some_interesting_list_items
    post_register_user
    created_user = User.all.first

    assert_equal(5, created_user.list_items.count)
    assert_equal("Try out Listabulous", created_user.list_items[0].text)
    assert_equal("Click on an item to mark it as complete", created_user.list_items[1].text)
    assert_equal("Click the coloured square on the left to change an items colour", created_user.list_items[2].text)
    assert_equal("Items are sorted by their colour, and their text", created_user.list_items[3].text)
    assert_equal("Click the cross on the right to delete an item", created_user.list_items[4].text)

    assert_equal("#69D2E7", created_user.list_items[0].colour)
    assert_equal("#69D2E7", created_user.list_items[1].colour)
    assert_equal("#69D2E7", created_user.list_items[2].colour)
    assert_equal("#69D2E7", created_user.list_items[3].colour)
    assert_equal("#69D2E7", created_user.list_items[4].colour)

    assert_equal(true, created_user.list_items[0].complete)
    assert_equal(false, created_user.list_items[1].complete)
    assert_equal(false, created_user.list_items[2].complete)
    assert_equal(false, created_user.list_items[3].complete)
    assert_equal(false, created_user.list_items[4].complete)
  end

  def test_post_register_encrypts_user_id_and_sets_cookie
    post_register_user
    follow_redirect!

    created_user = User.all.first

    encrypted = StringEncryption.new.encrypt(created_user._id.to_s)

    assert_not_nil(last_request.cookies["user"])
    assert_equal(encrypted, last_request.cookies["user"])
  end

  def test_post_register_sets_non_persistent_cookie_when_remember_is_not_checked
    post_register_user
    assert_no_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])  
  end

  def test_post_register_sets_persistent_cookie_when_remember_is_checked
    post '/register', {:email => "email@address.com", :display_name => "Timmy", :password => "some password", :password_confirmation => "some password", :remember => "on" }
    assert_match(/expires=..., \d\d-...-\d\d\d\d \d\d:\d\d:\d\d .../, last_response["Set-Cookie"])
  end

  def test_post_register_redirects_to_home_after_successful_account_creation
    post_register_user
    assert(last_response.redirect?)
  end

  def test_post_register_displays_error_when_email_already_exists    
    post_register_user
    post_register_user

    assert(last_response.body.include?("Email has already been taken"))
  end

  def test_get_logout_clears_cookies
    user = get_new_user
    post_login

    get '/logout'
    assert(last_response.redirect?)
    follow_redirect!
    assert_nil(last_request.cookies["user"])
  end

  def test_set_user_default_colour_sets_colour
    user = get_new_user
    post_login
    post '/api/set-user-default-colour', { :default_colour => "Blue"}
    user.reload
    assert_equal("Blue", user.default_colour)
  end

  def test_add_list_item_adds_item
    user = get_new_user
    post_login

    text = "This is my new list item!"
    colour = "black as my soul"
    post '/api/add-list-item', { :text => text, :colour => colour }

    user.reload
    list_item = user.list_items.first
    assert_equal(1, user.list_items.count)
    assert_equal(text, list_item.text)
    assert_equal(colour, list_item.colour)
  end

  def test_add_list_item_returns_list_item_view
    user = get_new_user
    post_login

    text = "This is my new list item!"
    colour = "black as my soul"
    post '/api/add-list-item', { :text => text, :colour => colour }
    user.reload

    app.new do |erb_app|
      expected_response_body = erb_app.erb :list_item, :layout => false, :locals => { :list_item => user.list_items.first }
      assert_equal(expected_response_body, last_response.body)
    end
  end

  def test_delete_list_item_deletes_item
    user = get_new_user
    post_login

    text = "This is my new list item!"
    colour = "black as my soul"
    user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
    user.save

    post '/api/delete-list-item', { :id => user.list_items.first._id.to_s }
    user.reload
    assert_equal(0, user.list_items.count)
  end

  def test_set_list_item_colour_sets_item_colour
    user = get_new_user
    post_login

    text = "This is my new list item!"
    colour = "black as my soul"
    user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
    user.save

    post '/api/set-list-item-colour', { :id => user.list_items.first._id.to_s, :colour => "white"}
    user.reload
    assert_equal("white", user.list_items.first.colour)
  end

  def test_mark_list_item_complete_marks_item_complete
    user = get_new_user
    post_login

    text = "This is my new list item!"
    colour = "black as my soul"
    user.list_items << ListItem.new(:text => text, :colour => colour, :complete => false)
    user.save

    post '/api/mark-list-item-complete', { :id => user.list_items.first._id.to_s, :complete => true}
    user.reload
    assert_equal(true, user.list_items.first.complete)
  end

  def test_statistics_page_renders
    get '/statistics'
    assert(last_response.body.include?('<legend>Statistics</legend>'))
  end

  def test_statistics_page_displays_user_count
    1.upto 11 do |number|
      user = create_user("email#{number}@address.com", "password01", "password01", "Jonny", "green")
      user.save
    end

    get '/statistics'
    assert(last_response.body.include?('Users: 11'))
  end

end