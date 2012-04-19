require File.join(Dir.pwd, "lib", "crypto")

class Pad < Sequel::Model
  # Creates a new pad with the text and password.
  def initialize(text, password)
    salt = Crypto.generate_salt
    encrypted_text, iv = Crypto.encrypt(text, password, salt)
    hashed_password = Crypto.hash_password(password, salt)
    super(:hash_id => Crypto.generate_hash_id, :text => encrypted_text, :salt => salt,
        :hashed_password => hashed_password, :die_time => Time.now + 3600 * 24 * 7, # 7 days from now
        :encrypt_method => "password", :iv => iv)
  end

  def validate
    super
    # add validations
  end

  def correct_pass?(password)
    Crypto.hash_password(password, self.salt) == self.hashed_password
  end

  def decrypt_text(password)
    begin
      Crypto.decrypt(self.text, password, self.salt, self.iv)
    rescue
      ""
    end
  end
end