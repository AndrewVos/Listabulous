require 'mongo_mapper'
require 'user'
require 'list_item'

def create_user(email, password, password_confirmation, display_name, default_colour)
  user = User.new
  user.email = email
  user.password = password
  user.password_confirmation = password_confirmation
  user.display_name = display_name
  user.default_colour = default_colour
  user
end

def create_list_item(text, colour, complete)
  list_item = ListItem.new
  list_item.text = text
  list_item.colour = colour
  list_item.complete = complete
  list_item
end