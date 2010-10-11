require 'spec'
require 'email'

describe Email do
  describe "::send" do
    it "sends an email with the sendgrid environment details using Pony" do
      ENV['SENDGRID_USERNAME'] = "test username"
      ENV['SENDGRID_PASSWORD'] = "test password"
      ENV['SENDGRID_DOMAIN'] = "test domain"

      Pony.should_receive(:mail).with(
      :to => "email@address.com",
      :subject => "subject",
      :body => "body",
      :from => "noreply@listabulous.co.uk",      
      :headers => { 'Content-Type' => 'text/html' },      
      :via => :smtp,
      :via_options => {
        :address        => "smtp.sendgrid.net",
        :port           => "25",
        :authentication => :plain,
        :user_name      => "test username",
        :password       => "test password",
        :domain         => "test domain"
      }).once
      Email::send("email@address.com", "subject", "body")
    end
  end
end