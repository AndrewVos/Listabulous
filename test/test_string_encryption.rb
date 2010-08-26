require 'test/unit'
require 'string_encryption'

class TestStringEncryption < Test::Unit::TestCase
  def test_encrypt_decrypt_string
    encryptor = StringEncryption.new
    string = "Some string value"
    
    encrypted = encryptor.encrypt(string)
    assert_not_equal(string, encrypted)

    decrypted = encryptor.decrypt(encrypted)
    assert_equal(string,decrypted)
  end
end