require File.join(Dir.pwd, "lib", "crypto")

class PadFile < Sequel::Model

  many_to_one :pad

  def initialize(params)
    salt = Crypto.generate_salt
    encrypted_file_path = "#{params[:temp_file_path]}.encrypted"
    iv = Crypto.encrypt_file(params[:temp_file_path], encrypted_file_path, params[:password], salt)
    File.delete(params[:temp_file_path])
    AWS::S3::S3Object.store(params[:filename], File.open(encrypted_file_path), AWS_BUCKET)
    File.delete(encrypted_file_path)
    super(:iv => iv, :salt => salt, :pad_id => params[:pad_id], :filename => params[:filename])
  end

  # TODO: test these paths
  def get_decrypted_file(password)
    raise "file not found" unless File.exists? path_to_file
    Crypto.decrypt_file(path_to_file, password, self.salt, self.iv)
  end

  def before_destroy
    # return "" unless File.exists? path_to_file
    # File.delete path_to_file
  end

end
