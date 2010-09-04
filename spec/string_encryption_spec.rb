require 'string_encryption'

describe StringEncryption do
  before :each do
    ENV["COOKIE_ENCRYPTION_KEY"] = "\022\032\361\306|\225\206\204\242\202\262\025e>j2I\021\222[r\334\305H\250\334\003k\201\366~S"
    ENV["COOKIE_ENCRYPTION_IV"] = "+\325\310;^\031d\237\243_\336\356\235\203\3525"
  end

  it "should encrypt and decrypt strings" do
    encryptor = StringEncryption.new
    string = "Some string value"

    encrypted = encryptor.encrypt(string)
    encrypted.should_not == string

    decrypted = encryptor.decrypt(encrypted)
    decrypted.should == string
  end
end