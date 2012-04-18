require File.join(Dir.pwd, "lib", "crypto")

class Pad < Sequel::Model
  # Creates a new pad with the text and password.
  def initialize(text, password)
    salt = Crypto.generate_salt
    encrypted_text, iv = Crypto.encrypt(text, password, salt)
    encrypted_success, _ = Crypto.encrypt("success", password, salt, iv)
    super(:hash_id => Crypto.generate_hash_id, :text => encrypted_text, :salt => salt,
        :success => encrypted_success, :die_time => Time.now + 3600 * 24 * 7, # 7 days from now
        :encrypt_method => "password", :iv => iv)
  end

  def validate
    super
    # add validations
  end

  def correct_pass?(password)
    begin # TODO(noam): see if there's a better way to do this.
      Crypto.decrypt(self.success, password, self.salt, self.iv) == "success"
    rescue
      false
    end
  end

  def decrypt_text(password)
    begin
      Crypto.decrypt(self.text, password, self.salt, self.iv)
    rescue
      ""
    end
  end
end