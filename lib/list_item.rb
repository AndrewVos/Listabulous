require 'mongo_mapper'
require 'user'

class ListItem
  include MongoMapper::EmbeddedDocument

  key :text, String
  key :colour, String
  key :complete, Boolean

  validates_presence_of :text
  validates_presence_of :colour
  validates_presence_of :complete
end
