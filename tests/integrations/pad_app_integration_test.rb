require "faraday"
require "rspec"
require "rack/test"
require "json"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "all")
require "net/http"

# TODO: add tests to see if client side encryption works
# TODO: deleting pad when authorized and when not.
# TODO: test that files and security options get deleted when pad is destroyed


describe "The Pad App" do

  before(:all) do
    @simplePass = "mypass"
    @simpleText = "mytext"
    @conn = Faraday.new(:url => "http://localhost:8080") do |builder|
      builder.request :multipart
      builder.request :url_encoded
      builder.request :json
      builder.adapter :net_http
    end
  end

  it "creates a pad and then retrieves it while using server side encryption" do
    # Creating the pad
    hash_id = create_simple_pad

    # Checking retrieving works
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
    last_response.status.should == 200
    JSON.parse(last_response.body)["text"].should == @simpleText
    JSON.parse(last_response.body)["encrypt_method"].should == "server_side"

    # Deletes the pad
    Pad[:hash_id => hash_id].destroy
  end

  it "returns a 401 for retrieving a pad with incorrect password" do
    # Creating the pad
    hash_id = create_simple_pad

    # Checking retrieving works
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass.reverse}"
    last_response.status.should == 401
    last_response.body.should == "incorrect password"

    # Deletes the pad
    Pad[:hash_id => hash_id].destroy
  end

  it "doesn't let users destroy a pad before authentication" do
    # Creating the pad
    hash_id = create_simple_pad(:allowReaderToDestroy => true)

    # Checking deletion route
    last_response = @conn.delete "/pads/#{hash_id}"
    last_response.status.should == 401

    Pad[:hash_id => hash_id].destroy
  end

  it "doesn't let users destroy a pad if allow reader to destroy isn't set" do
    # Creating the pad
    hash_id = create_simple_pad

    # Authenticating
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
    last_response.status.should == 200

    # Checking deletion route
    last_response = @conn.delete "/pads/#{hash_id}", { "Cookie" => last_response.headers["set-cookie"] }
    last_response.status.should == 401

    Pad[:hash_id => hash_id].destroy
  end


  it "lets users destroy a pad after authenticating if allow reader to destroy is set" do
    # Creating the pad
    hash_id = create_simple_pad(:allowReaderToDestroy => true)

    # Authenticating
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
    last_response.status.should == 200

    # Checking deletion route
    # TODO: fix this! it's not working because of xcrf
    last_response = @conn.delete "/pads/#{hash_id}", { "Cookie" => last_response.headers["set-cookie"] }
    last_response.status.should == 200

    Pad[:hash_id => hash_id].destroy
  end

  it "doesn't try to authenticate after more tries than allowed and before wait time" do
    hash_id = fail_auth_allowed_times

    # Trying to authenticate after more than allowed failed attempts
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
    last_response.status.should == 401
    last_response.body.should == "Too many attempts, please wait"

    Pad[:hash_id => hash_id].destroy
  end

  it "tries to authenticate after wait time has been achieved" do
    hash_id = fail_auth_allowed_times

    # TODO: change wait time to 0

    # Trying to authenticate after more than allowed failed attempts
    last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
    last_response.status.should == 200

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
      hash_id = create_pad_with_file(" ", "#{@simplePass}")

      # Authenticating the user for the pad
      last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
      last_response.status.should == 200
      JSON.parse(last_response.body)["filenames"].should == [@filename]

      # Checking retrieving works
      last_response = @conn.get("/pads/#{hash_id}/files/#{@filename}",
          { "Cookie" => last_response.headers["set-cookie"] })
      last_response.status.should == 200
      last_response.body.should == "#{@file_text}\n"

      # Deletes the pad and the file
      Pad[:hash_id => hash_id].destroy
    end

    it "creates a pad with more files then allowed and checks that only first 4 were recieved" do
      # Creating the pad
      file_to_send = []
      (0..4).each do
        file_to_send.push Faraday::UploadIO.new(@filename, "application/form-data")
      end
      last_response = @conn.post "/pads", { :text => " ", :password => @simplePass, :file0 => file_to_send[0],
        :file1 => file_to_send[1], :file2 => file_to_send[2], :file3 => file_to_send[3],
        :file4 => file_to_send[4] }
      last_response.status.should == 200
      hash_id = JSON.parse(last_response.body)["hash_id"]

      # Authenticating the user for the pad
      last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass}"
      last_response.status.should == 200
      JSON.parse(last_response.body)["filenames"].should == [@filename, @filename, @filename, @filename]

      # Deletes the pad and the file
      Pad[:hash_id => hash_id].destroy
    end

    it "redirects to login page when trying to download a file without authenticating" do
      # Creating the pad
      hash_id = create_pad_with_file(" ", @simplePass)

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

  def create_simple_pad(security_options = {})
    last_response = @conn.post "/pads", { :text => @simpleText, :password => @simplePass,
        :securityOptions => security_options.to_json }
    last_response.status.should == 200
    JSON.parse(last_response.body)["hash_id"]
  end

  def create_pad_with_file(text, password)
    file_to_send = Faraday::UploadIO.new(@filename, "application/form-data")
    last_response = @conn.post "/pads", { :text => text, :password => password, :file0 => file_to_send }
    last_response.status.should == 200
    JSON.parse(last_response.body)["hash_id"]
  end

  def fail_auth_allowed_times
    # Creating the pad
    hash_id = create_simple_pad
    # trying to authenticate with the wrong password
    (1..FailedAttempt::ATTEMPTS_ALLOWED).each do
      last_response = @conn.get "/pads/#{hash_id}/authenticate?password=#{@simplePass.reverse}"
      last_response.status.should == 401
      last_response.body.should == "incorrect password"
    end
    hash_id
  end

end