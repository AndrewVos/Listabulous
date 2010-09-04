require 'test/unit'
require 'string_encryption'

class TestStringEncryption < Test::Unit::TestCase
  
  def setup
    ENV["COOKIE_ENCRYPTION_KEY"] = "\022\032\361\306|\225\206\204\242\202\262\025e>j2I\021\222[r\334\305H\250\334\003k\201\366~S"
    ENV["COOKIE_ENCRYPTION_IV"] = "+\325\310;^\031d\237\243_\336\356\235\203\3525"
  end
  
  def test_encrypt_decrypt_string
    puts ENV["COOKIE_ENCRYPTION_KEY"]
    encryptor = StringEncryption.new
    string = "Some string value"
    
    encrypted = encryptor.encrypt(string)
    assert_not_equal(string, encrypted)

    decrypted = encryptor.decrypt(encrypted)
    assert_equal(string,decrypted)
  end
  
end