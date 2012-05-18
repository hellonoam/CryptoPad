require File.join(Dir.pwd, "lib", "crypto")

class PadFile < Sequel::Model

  many_to_one :pad

  def initialize(params)
    salt = Crypto.generate_salt
    encrypted_file_path = "#{params[:temp_file_path]}.encrypted"
    iv = Crypto.encrypt_file(params[:temp_file_path], encrypted_file_path, params[:password], salt)
    File.delete(params[:temp_file_path])
    AWS::S3::S3Object.store("#{self.pad.hash_id}/#{params[:filename]}", File.open(encrypted_file_path), PadApp::AWS_BUCKET)
    File.delete(encrypted_file_path)
    super(:iv => iv, :salt => salt, :pad_id => params[:pad_id], :filename => params[:filename])
  end

  # TODO: test these paths
  def get_decrypted_file(password)
    raise "file not found" unless s3_object_exists?
    Crypto.decrypt_file(key, PadApp::AWS_BUCKET, password, self.salt, self.iv)
  end

  def before_destroy
    AWS::S3::S3Object.delete(key, PadApp::AWS_BUCKET) if s3_object_exists?
  end

  def s3_object_exists?
    AWS::S3::S3Object.exists?(key, PadApp::AWS_BUCKET)
  end

  def key
    "#{self.pad.hash_id}/#{self.filename}"
  end
end
