require "digest/sha2"
require "base64"
require "openssl"

module Crypto
  RANDOM_STRING = "cryptoPadRulz"
  @@CHARSET = [('a'..'z'),('A'..'Z'),('0'..'9')].map{ |i| i.to_a }.flatten

  # Encrypts the plain_text using the password and salt, the result is base64 encoded.
  def self.encrypt(plain_text, password, salt, iv = nil)
    password = Digest::SHA256.digest(password + RANDOM_STRING + salt)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.encrypt
    aes.key = key
    iv ||= Base64::encode64(aes.random_iv)
    aes.iv = iv
    [Base64::encode64(aes.update(plain_text) + aes.final), iv]
  end

  # Decrypts
  def self.decrypt(encrypted_text, password, salt, iv)
    encrypted_text = Base64::decode64(encrypted_text)
    password = Digest::SHA256.digest(password + RANDOM_STRING + salt)
    key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, 2000, 256)
    aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.key = key
    aes.iv = iv
    aes.update(encrypted_text) + aes.final
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