configure do
  enable :sessions
end

configure :production do
  ENV["SERVER_NAME"] = "listabulous.co.uk"
  mongohq_url = ENV['MONGOHQ_URL']
  MongoMapper.connection = Mongo::Connection.from_uri(mongohq_url)
  MongoMapper.database = mongohq_url[mongohq_url.rindex("/") + 1, mongohq_url.length]
end

configure :development do
  MongoMapper.database = "Listabulous"

class Email
  def self.send(to, subject, body)
    puts "==Sending Email=="
    puts "To: #{to}"
    puts "Subject: #{subject}"
    puts "Body: #{body}"
  end
end

  ENV["COOKIE_ENCRYPTION_KEY"] = "x/$\233E,\232M\221\261\373\315t\205\003\371D\r\347d\277\026*?&\302c@N\375\245j"
  ENV["COOKIE_ENCRYPTION_IV"] = "\031\356z\354E\315\367\313\343i\216\321m=\336\275"  
end