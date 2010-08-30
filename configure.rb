configure do
  enable :sessions
end

configure :production do
  # mongodb://app274790:7832nmwusv7of7nqr71yzu@flame.mongohq.com:27035/app274790
  mongohq_url = ENV['MONGOHQ_URL']
  MongoMapper.connection = Mongo::Connection.from_uri(mongohq_url)
  MongoMapper.database = mongohq_url[mongohq_url.rindex("/") + 1, mongohq_url.length]
end

configure :development do
  MongoMapper.database = "Listabulous"
end