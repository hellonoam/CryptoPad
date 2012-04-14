require File.join(Dir.pwd, "lib", "crypto")

class Pad < Sequel::Model
  def initialize(text, password)
    salt = Crypto.generate_salt
    encrypted_text = Crypto.encrypt(text, password, salt)
    encrypted_success = Crypto.encrypt("success", password, salt)
    super(:hash_id => Crypto.digest(encrypted_text), :text => encrypted_text, :salt => salt,
        :success => encrypted_success, :die_time => Time.now + 3600 * 24 * 3, # 3 days from now
        :encrypt_method => "password")
  end

  def validate
    super
    # add validations
  end

  def correct_pass?(password)
    begin # TODO(noam): see if there's a better way to do this.
      Crypto.decrypt(self.success, password, self.salt) == "success"
    rescue
      false
    end
  end

  def decrypt_text(password)
    begin
      Crypto.decrypt(self.text, password, self.salt)
    rescue
      ""
    end
  end
end