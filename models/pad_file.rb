require File.join(Dir.pwd, "lib", "crypto")

class PadFile < Sequel::Model

  many_to_one :pad

  def initialize(params)
    salt = Crypto.generate_salt
    iv = Crypto.encrypt_file(params[:temp_file_path], params[:new_file_path], params[:password], salt)
    File.delete(params[:temp_file_path])
    super(:iv => iv, :salt => salt, :pad_id => params[:pad_id], :filename => params[:filename])
  end

  def get_decrypted_file(password)
    path_to_file = "#{Dir.pwd}/file_transfers/#{self.pad.hash_id}/#{self.filename}"
    Crypto.decrypt_file(path_to_file, password, self.salt, self.iv)
  end

  def before_destroy
    # add error handling - if file doesn't exist don't throw an error but if delete failed throw error.
    File.delete "#{Dir.pwd}/file_transfers/#{self.pad.hash_id}/#{self.filename}"
  end

end
