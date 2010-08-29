require 'mongo_mapper'
require 'list_item'
require 'rfc-822'
require 'digest/sha1'

class User
  include MongoMapper::Document
  
  key :email, String, :unique => true
  key :password, String
  key :display_name, String
  key :default_colour, String
  many :list_items
  
  validates_presence_of :email
  validates_format_of :email, :with => RFC822::EMAIL, :allow_nil => true
  validates_presence_of :password
  validates_presence_of :display_name
  validates_presence_of :default_colour
  validates_associated :list_items
  
  before_save :hash_password
  
  def hash_password
    if new_record?
      @password = Digest::SHA1.hexdigest(@password)
    end
  end
end