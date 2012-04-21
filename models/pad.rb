require File.join(Dir.pwd, "lib", "crypto")
require "json"

class Pad < Sequel::Model
  # Creates a new pad with the text and password.
  def initialize(params)
    args = Hash.new
    [:encrypt_method, :encrypted_text, :iv, :salt].each { |sym| args[sym] = params[sym]}
    args[:hash_id] = Crypto.generate_hash_id
    args[:die_time] = Time.now + 3600 * 24 * 7 # 7 days from now
    args[:salt] ||= Crypto.generate_salt
    args[:hashed_password] = Crypto.hash_password(params[:password], args[:salt])
    unless args[:encrypt_method] == "client-side"
      args[:encrypt_method] = "server-side"
      args[:encrypted_text], args[:iv] = Crypto.encrypt(params[:text], params[:password], args[:salt])
    end
    super(args)
  end

  def validate
    super
    # add validations
  end

  def public_model
    self.to_json
  end

  def correct_pass?(password)
    Crypto.hash_password(password, self.salt) == self.hashed_password
  end

  def decrypt_text(password)
    begin
      Crypto.decrypt(self.encrypted_text, password, self.salt, self.iv)
    rescue
      ""
    end
  end
end