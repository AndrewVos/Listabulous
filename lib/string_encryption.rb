require 'openssl'
require 'base64'
require 'uri'

class StringEncryption
  def initialize
    @key = ENV["COOKIE_ENCRYPTION_KEY"]
    @iv = ENV["COOKIE_ENCRYPTION_IV"]
  end
  
  def encrypt(string)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = @key
    cipher.iv = @iv
    encrypted = cipher.update(string) + cipher.final
  end
  
  def decrypt(string)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = @key
    cipher.iv = @iv
    decrypted = cipher.update(string) + cipher.final
  end
end