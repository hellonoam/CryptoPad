require "digest/sha2"
require "base64"
require "openssl"

module Crypto
  AES_IV = "57e72a8de8529d189a0a9e9364855398921"

  def self.encrypt(plain_text, password, salt)
    key = Digest::SHA256.digest(password + salt)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.encrypt
    aes.key = key
    aes.iv = AES_IV
    Base64::encode64(aes.update(plain_text) + aes.final)
  end

  def self.decrypt(encrypted_text, password, salt)
    encrypted_text = Base64::decode64(encrypted_text)
    key = Digest::SHA256.digest(password + salt)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.key = key
    aes.iv = AES_IV
    aes.update(encrypted_text) + aes.final
  end

  def self.digest(text)
    Base64::encode64(Digest::SHA256.hexdigest(text + Time.now.to_s))[1..16]
  end

  def self.generate_salt
    self.digest("#{Time.now.to_s}cryptoPadRulz#{Random.rand(100)}")[1..5]
  end
end