require 'rubygems'
require 'mongo_mapper'
require 'user'
require 'spec_helper_methods'

MongoMapper.database = "ListabulousTest"

describe ListItem do
  before :each do
    User.collection.remove
  end
  
  describe ".save" do
    context "empty text" do
      it "does not save" do
        user = create_user("email@address.com", "password1", "password1", "John Doe", "Pink")
        list_item = create_list_item(nil, "red", false)

        user.list_items << list_item
        user.save.should == false
        user.errors.count.should == 1
        list_item.errors.on(:text).should_not == nil
      end
    end
    
    context "empty colour" do
      it "does not save" do
        user = create_user("email@address.com", "password1", "password1", "John Doe", "Pink")
        list_item = create_list_item("some text", nil, false)

        user.list_items << list_item
        user.save.should == false
        user.errors.count.should == 1
        list_item.errors.on(:colour).should_not == nil
      end
    end
    
    context "empty complete" do
      it "does not save" do
        user = create_user("email@address.com", "password1", "password1", "John Doe", "Pink")
        list_item = create_list_item("some text", "red", nil)

        user.list_items << list_item
        user.save.should == false
        user.errors.count.should == 1
        list_item.errors.on(:complete).should_not == nil
      end
    end
  end
end