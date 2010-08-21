require 'string_encryption'

class Authentication
  
  def initialize(cookies)
    @cookies = cookies
    @string_encyption = StringEncryption.new
  end
  
  def current_user
    return nil if @cookies.has_key?(:session_id) == false
    
    decrypted = @string_encyption.decrypt(@cookies[:session_id])
  end
  
  def login(username)
    encrypted = @string_encyption.encrypt(username)
    @cookies[:session_id] = encrypted
  end
  
  def logout
    @cookies[:session_id] = nil
  end
  
end