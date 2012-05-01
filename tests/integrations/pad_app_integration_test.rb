require "faraday"
require "rspec"
require "rack/test"
require "json"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "all")
require "net/http"

# TODO: add tests to check file limits
# TODO: add tests to see if client side encryption works
# TODO: add tests for no password
# TODO: deleting pad when authorized and when not.


describe "The Pad App" do

  before(:all) do
    @conn = Faraday.new(:url => "http://localhost:8080") do |builder|
      builder.request :multipart
      builder.request :url_encoded
      builder.request :json
      builder.adapter :net_http
    end
  end

  it "creates a pad and then retrieves it while using server side encryption" do
    # Creating the pad
    last_response = @conn.post "/pads", { :text => "mytext", :password => "mypass" }
    last_response.status.should == 200
    hash_id = JSON.parse(last_response.body)["hash_id"]

    # Checking retrieving works
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=mypass"
    last_response.status.should == 200
    JSON.parse(last_response.body)["text"].should == "mytext"
    JSON.parse(last_response.body)["encrypt_method"].should == "server_side"

    # Deletes the pad
    Pad[:hash_id => hash_id].destroy
  end

  describe "file upload" do
    before(:each) do
      # Creating the file to send
      @filename = "myfile.temp"
      @file_text = "text of file"
      File.open(@filename, "w") { |f| f.puts @file_text }
    end

    it "creates a pad with a file and checks that retrieving the file works" do
      # Creating the pad
      hash_id = create_pad_with_file(" ", "mypass")

      # Authenticating the user for the pad
      last_response = @conn.get "/pads/#{hash_id}/authenticate?password=mypass"
      last_response.status.should == 200
      JSON.parse(last_response.body)["filenames"].should == [@filename]

      # Checking retrieving works
      last_response = @conn.get("/pads/#{hash_id}/files/#{@filename}",
          { "Cookie" => last_response.headers["set-cookie"]})
      last_response.status.should == 200
      last_response.body.should == "#{@file_text}\n"

      # Deletes the pad and the file
      Pad[:hash_id => hash_id].destroy
    end

    it "redirects to login page when trying to download a file without authenticating" do
      # Creating the pad
      hash_id = create_pad_with_file(" ", "mypass")

      # Checking retrieving redirects
      last_response = @conn.get "/pads/#{hash_id}/files/#{@filename}"
      last_response.status.should == 302
      URI.parse(last_response.headers["location"]).path.should == "/pads/#{hash_id}"

      # Deletes the pad and the file
      Pad[:hash_id => hash_id].destroy
    end

    after(:each) do
      File.delete(@filename)
    end
  end

  def create_pad_with_file(text, password)
    file_to_send = Faraday::UploadIO.new(@filename, "application/form-data")
    last_response = @conn.post "/pads", { :text => text, :password => password, :file0 => file_to_send }
    last_response.status.should == 200
    JSON.parse(last_response.body)["hash_id"]
  end
end