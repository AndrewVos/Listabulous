require 'mongo_mapper'
require 'list_item'
require 'rfc-822'
require 'digest/sha1'

class User
  include MongoMapper::Document

  key :email, String, :unique => true
  key :password, String
  attr_accessor :password_confirmation
  key :display_name, String
  key :default_colour, String
  key :forgotten_password_key, String
  many :list_items

  validates_presence_of :email
  validates_format_of :email, :with => RFC822::EMAIL, :allow_nil => true
  validates_presence_of :password
  validates_confirmation_of :password
  validates_presence_of :display_name
  validates_presence_of :default_colour
  validates_associated :list_items

  before_save :downcase_email  
  before_save :hash_password
  before_validation :copy_password_confirmation

  private

  def downcase_email
    @email.downcase!
  end

  def hash_password
    if password_changed?
      @password = Digest::SHA1.hexdigest(@password)
    end
  end

  def copy_password_confirmation
    if new_record? == false
      @password_confirmation = @password
    end
  end
end