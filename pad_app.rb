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

  get "/js/*.coffee" do |fileName|
    content_type "text/javascript", :charset => "utf-8"
    coffee "/js/#{fileName}".to_sym
  end

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
    pad_link = "localhost:8080/pads/#{params[:hash_id]}"
    erb :link, :locals => { :pad_link => pad_link }
  end

  get "/pads/:hash_id/authenticate" do
    pad = Pad[:hash_id => params[:hash_id]]
    halt 401, "incorrect password" unless pad.correct_pass?(params[:password])
    pad.decrypt_text(params[:password])
  end

  post "/pads" do
    pad = Pad.new(params[:text], params[:password])
    pad.save
    content_type "application/json"
    { :hash_id => pad.hash_id.to_s }.to_json
  end

  private

  def render_with_layout(template)
    erb :base, :locals => {:template => template }
  end
end
  