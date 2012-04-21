require File.join(Dir.pwd, "lib", "crypto")
require "rspec"
require "rack/test"

ENV["RACK_ENV"] = "test"

describe "Crypto" do

  it "encrypts and then decrypts some text" do
    plain_text = "plain_text"
    encrypted_text, iv = Crypto.encrypt(plain_text, "password", "salt")
    Crypto.decrypt(encrypted_text, "password", "salt", iv).should == plain_text
    plain_text.should_not == encrypted_text
  end

  it "hashes passwords correctly" do
    hashed_password = Crypto.hash_password("password", "salt")
    hashed_password.should == Crypto.hash_password("password", "salt")
    (hashed_password.index("password") || hashed_password.index("salt")).should == nil
  end

end