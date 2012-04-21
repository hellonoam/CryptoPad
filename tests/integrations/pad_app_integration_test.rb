require "faraday"
require "rspec"
require "rack/test"
require "json"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "pad")

describe "The Pad App" do

  @@conn = Faraday.new(:url => "http://localhost:8080") do |builder|
    builder.request :url_encoded
    builder.request :json
    builder.adapter :net_http
  end

  it "creates a pad and then retrieves it" do
    # Adding a new pad
    last_response = @@conn.post "/pads", { :text => "mytext", :password => "mypass" }
    last_response.status.should == 200
    hash_id = JSON.parse(last_response.body)["hash_id"]

    # Checking retrieving works
    last_response = @@conn.get "/pads/#{hash_id}/authenticate?password=mypass"
    last_response.status.should == 200
    (last_response.body == "mytext").should == true

    # Deletes the pad
    Pad[:hash_id => hash_id].destroy
  end

end