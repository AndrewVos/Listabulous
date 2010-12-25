require 'rubygems'
require 'pony'

class Email
  def self.send(to, subject, body)
    Pony.mail(
      :to => to,
      :subject => subject,
      :body => body,
      :from => "noreply@listabulous.co.uk",
      :headers => { "Content-Type" => "text/html" },
      :via => :smtp,
      :via_options => {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SENDGRID_DOMAIN']
    })
  end
end
