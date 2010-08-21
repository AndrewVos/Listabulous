require 'openssl'
require 'base64'
require 'uri'
require 'sinatra'
class StringEncryption
  
  def key
    "x/$\233E,\232M\221\261\373\315t\205\003\371D\r\347d\277\026*?&\302c@N\375\245j"
  end
  
  def iv
    "\031\356z\354E\315\367\313\343i\216\321m=\336\275"
  end

  def encrypt(string)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv
    encrypted = cipher.update(string) + cipher.final
  end
  
  def decrypt(string)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = key
    cipher.iv = iv
    decrypted = cipher.update(string) + cipher.final
  end
  
end