require 'mongo_mapper'
require 'rfc-822'

class User
  include MongoMapper::Document
  
  key :email, String, :unique => true
  key :password, String
  key :display_name, String
  key :default_colour, String
  
  validates_presence_of :email
  validates_format_of :email, :with => RFC822::EMAIL, :allow_nil => true
  validates_presence_of :password
  validates_presence_of :display_name
  validates_presence_of :default_colour
end