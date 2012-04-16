require "sinatra/base"
require "set"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "pad")
require "coffee-script"
require "sass"

class PadApp < Sinatra::Base

  set :public_folder, "public"

  enable :logging

  configure :development do
    use Rack::CommonLogger
    $stderr.sync
    $debug_mode = true

    require "sinatra/reloader"
    register Sinatra::Reloader
    also_reload "*/*.rb"
  end

  # Compile coffeescript files that are in the views folder
  get "/js/*.coffee" do |fileName|
    content_type "text/javascript", :charset => "utf-8"
    coffee "/js/#{fileName}".to_sym
  end

  # Compile scss files that are in the views folder
  get "/css/*.scss" do |fileName|
    content_type "text/css", :charset => "utf-8"
    scss "/css/#{fileName}".to_sym, :style => :expanded
  end

  get "/" do
    render_with_layout(:index)
  end

  get "/create" do
    render_with_layout(:create)
  end

  get "/pads/:hash_id" do
    render_with_layout(:pad)
  end

  get "/link/:hash_id" do
    port = (request.port == 80 || request.port == 443) ? "" : ":#{request.port}"
    pad_link = "#{request.scheme}://#{request.host}#{port}/pads/#{params[:hash_id]}"
    erb :link, :locals => { :pad_link => pad_link }
  end

  # Returns the pad's text if the password was correct
  get "/pads/:hash_id/authenticate" do
    pad = Pad[:hash_id => params[:hash_id]]
    halt 400, "invalid hash_id" if pad.nil?
    halt 401, "incorrect password" unless pad.correct_pass?(params[:password])
    pad.decrypt_text(params[:password])
  end

  # Creates and new pad and returns the hash_id
  post "/pads" do
    pad = Pad.new(params[:text], params[:password])
    pad.save
    content_type "application/json"
    { :hash_id => pad.hash_id.to_s }.to_json
  end

  private

  # Renders the template with the base template which requires the template's coffee and scss file.
  def render_with_layout(template)
    erb :base, :locals => {:template => template }
  end
end
  