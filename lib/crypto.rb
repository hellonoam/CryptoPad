require "digest/sha2"
require "base64"
require "openssl"

module Crypto
  AES_IV = "57e72a8de8529d189a0a9e9364855398921"

  # Encrypts the plain_text using the password and salt, the result is base64 encoded.
  def self.encrypt(plain_text, password, salt)
    key = Digest::SHA256.digest(password + salt)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.encrypt
    aes.key = key
    aes.iv = AES_IV
    Base64::encode64(aes.update(plain_text) + aes.final)
  end

  # Decrypts
  def self.decrypt(encrypted_text, password, salt)
    encrypted_text = Base64::decode64(encrypted_text)
    key = Digest::SHA256.digest(password + salt)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.key = key
    aes.iv = AES_IV
    aes.update(encrypted_text) + aes.final
  end

  # Creates a hash of the given text using the currect time and a random number, hence the function will
  # return different results when calling it with the same args.
  def self.digest(text)
    Base64::encode64(Digest::SHA256.hexdigest(text + Time.now.to_s + Random.rand(100).to_s))[1..16]
  end

  def self.generate_salt
    self.digest("cryptoPadRulz")[1..5]
  end
end