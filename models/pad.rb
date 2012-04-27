require File.join(Dir.pwd, "lib", "crypto")
require "json"

class Pad < Sequel::Model

  one_to_many :pad_files
  one_to_one :pad_security_option

  # Creates a new pad with the text and password.
  def initialize(params)
    args = Hash.new
    [:encrypted_text, :iv, :salt, :encrypt_method].each { |sym| args[sym] = params[sym]}
    args[:hash_id] = Crypto.generate_hash_id
    args[:created_at] = Time.now
    args[:salt] ||= Crypto.generate_salt
    args[:hashed_password] = Crypto.hash_password(params[:password], args[:salt])
    unless args[:encrypt_method] == "client_side"
      args[:encrypt_method] = "server_side"
      args[:encrypted_text], args[:iv] = Crypto.encrypt(params[:text], params[:password], args[:salt])
    end
    super(args)
  end

  def validate
    super
    # TODO: add validations
  end

  # TODO: find out why dependency delete doesn't work
  def before_destroy
    self.pad_files.each { |f| f.destroy }
    self.pad_security_option.destroy
  end

  def filenames
    self.pad_files.map do |file|
      file.filename.to_s
    end
  end

  def public_model
    { :salt => self.salt, :iv => self.iv, :encrypted_text => self.encrypted_text,
      :encrypt_method => self.encrypt_method, :filenames => self.filenames }
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