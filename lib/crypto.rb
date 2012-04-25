require "digest/sha2"
require "base64"
require "openssl"

module Crypto
  RANDOM_STRING = "cryptoPadRulz"
  @@CHARSET = [('a'..'z'),('A'..'Z'),('0'..'9')].map{ |i| i.to_a }.flatten

  # Encrypts the plain_text using the password and salt, the result is base64 encoded.
  def self.encrypt(plain_text, password, salt)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.encrypt
    aes.key = key
    iv = Base64.strict_encode64(aes.random_iv)
    aes.iv = iv
    [Base64.strict_encode64(aes.update(plain_text) + aes.final), iv]
  end

  def self.encrypt_file(old_file_path, new_file_path, password, salt)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.encrypt
    aes.key = key
    iv = Base64.strict_encode64(aes.random_iv)
    aes.iv = iv
    decrypted_file = File.open(old_file_path)
    File.open(new_file_path, "w") do |f|
      loop do
        decrypted_buffer = decrypted_file.read(4096)
        break unless decrypted_buffer
        crypted_buffer = aes.update(decrypted_buffer)
        f << crypted_buffer
      end
      f << aes.final
    end
    iv
  end

  def self.decrypt_file(file_path, password, salt, iv)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.key = key
    aes.iv = iv
    data = ""
    File.open(file_path, "r") do |f|
      loop do
        crypted_buffer = f.read(4096)
        break unless crypted_buffer
        decrypted_buffer = aes.update(crypted_buffer)
        data << decrypted_buffer
      end
      data << aes.final
    end
    data
  end

  # Decrypts
  def self.decrypt(encrypted_text, password, salt, iv)
    encrypted_text = Base64.strict_decode64(encrypted_text)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.key = key
    aes.iv = iv
    aes.update(encrypted_text) + aes.final
  end

  def self.hash_password(password, salt)
    Base64.strict_encode64(Digest::SHA256.digest(password + RANDOM_STRING + salt))
  end

  # Creates a random string of length 'length', the string is built from chars specified in CHARSET
  def self.random_string(length)
    (1..length).map{ |char| @@CHARSET[Random.rand(@@CHARSET.length)] }.join
  end

  def self.generate_hash_id
    self.random_string(16)
  end

  def self.generate_salt
    self.random_string(5)
  end
end