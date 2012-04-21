require "pad_app"
require "rspec"
require "rack/test"

ENV["RACK_ENV"] = "test"

describe "The Pad App" do
  include Rack::Test::Methods

  def app
    PadApp
  end

  it "gets the index page" do
    get "/"
    last_response.should be_ok
  end

  it "adds a new user to the db" do
    json_request = { :email => "test@email.com" }
    stub_class_instantiation(User, false, json_request)
    post "/user", json_request
    last_response.should be_ok
    last_response.body.should == ""
  end

  it "adds a pad" do
    json_request = { :text => "mytext", :password => "pass" }
    pad = stub_class_instantiation(Pad, true, json_request)
    post "/pads", json_request
    last_response.should be_ok
    JSON.parse(last_response.body)["hash_id"].should == pad.hash_id
  end

  it "returns a 400 for a pad which does not exist" do
    Pad.stub(:[]).and_return(nil)
    get "/pads/hash_id/authenticate", { :password => "pass" }
    last_response.status.should == 400
  end

  it "returns a 401 if the passowrd is incorrect for a pad" do
    pad = double("Pad")
    Pad.stub(:[]).and_return(pad)
    pad.stub(:correct_pass?).and_return(false)
    get "/pads/hash_id/authenticate", { :password => "pass" }
    last_response.status.should == 401
  end

  it "gets the requested pad" do
    pad = Pad.new(:text => "text", :password => "password")
    Pad.stub(:[]).and_return(pad)
    get "/pads/hash_id/authenticate", { :password => "password" }
    last_response.should be_ok
  end

  def stub_class_instantiation(klass, convert_to_string, *args)
    instance = klass.new(*args)
    klass.stub(:new).and_return(instance)
    # This is a silly hack to convert the args' hash into a string => string hash if needed.
    if convert_to_string
      string_hash = Hash.new
      args[0].each { |k,v| string_hash[k.to_s] = v}
      klass.should_receive(:new).with(string_hash)
    else
      klass.should_receive(:new).with(*args)
    end
    instance.stub(:save).and_return(true)
    instance
  end
end