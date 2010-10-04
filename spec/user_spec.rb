require 'rubygems'
require 'mongo_mapper'
require 'spec_helper_methods'

MongoMapper.database = "ListabulousTest"

describe User do
  before :each do
    User.collection.remove
  end

  describe ".save" do
    context "empty email" do
      it "should not save" do
        user = create_user(nil, "thepassword", "thepassword", "John", "Red")

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:email).should_not == nil
      end
    end

    context "invalid email" do
      it "should not save" do
        user = create_user("not a valid email!", "thepassword", "thepassword", "John", "Red")

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:email).should_not == nil
      end
    end

    context "empty password" do
      it "should not save" do
        user = create_user("email@address.com", nil, nil, "John", "Red")

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:password).should_not == nil
      end
    end

    context "empty display name" do
      it "should not save" do
        user = create_user("email@address.com", "password", "password", nil, "Red")

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:display_name).should_not == nil

      end
    end

    context "empty default colour" do
      it "should not save" do
        user = create_user("email@address.com", "password", "password", "John Doe", nil)

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:default_colour).should_not == nil
      end
    end

    context "email has been used before" do
      it "should not save" do
        first_user = create_user("email@address.com", "password1", "password1", "John Doe", "red")
        first_user.save.should == true

        second_user = create_user("email@address.com", "password2", "password2", "John Doe", "red")

        second_user.save.should == false
        second_user.errors.count.should == 1
        second_user.errors.on(:email).should_not == nil
      end
    end

    context "email has trailing spaces" do
      it "should not save" do
        user = create_user("   email@address.com   ", "some password","some password", "John Doe", "red")

        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:email).should_not == nil
      end
    end

    context "upper case email address" do
      it "should downcase email address before saving" do
        user = create_user("EMAIL@address.com", "some password","some password", "John Doe", "red")
        user.save.should == true
        user.email.should == "email@address.com"
      end
    end

    it "should hash the users password" do
      user = create_user("email@address.com", "some password","some password", "John Doe", "red")
      user.save
      sha1 = Digest::SHA1.hexdigest("some password")
      user.password.should == sha1
    end

    context "user has been saved before" do
      it "should save again" do
        user = create_user("email@address.com", "some password","some password", "John Doe", "red")
        user.save.should == true
        user.save.should == true
      end
    end

    it "should only hash the password once" do
      user = create_user("email@address.com", "some password", "some password", "John Doe", "red")
      user.save
      sha1 = Digest::SHA1.hexdigest("some password")
      user.save
      user.password.should == sha1
    end

    context "password does not match confirmation password" do
      it "should not save" do
        user = create_user("email@address.com", "password", "different password", "John Doe", "red")
        user.save.should == false
        user.errors.count.should == 1
        user.errors.on(:password).should_not == nil
      end
    end

    it "should not save the password confirmation" do
      user = create_user("email@address.com", "password", "password", "John Doe", "red")
      user.save
      saved_user = User.all.first
      saved_user.password_confirmation.should == nil
    end    
  end
end