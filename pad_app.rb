require "sinatra/base"
require "set"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "pad")
require File.join(Dir.pwd, "models", "user")
require "coffee-script"
require "sass"
require "json"
require "fileutils"

class PadApp < Sinatra::Base

  set :public_folder, "public"

  enable :logging

  def initialize
    super
    puts do_cron_job
  end

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
    render_with_layout(:create, "sjcl.js", "crypto.coffee")
  end

  get "/pads/:hash_id" do
    render_with_layout(:pad, "sjcl.js", "crypto.coffee")
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
    content_type "application/json"
    if pad.encrypt_method == "client_side"
      pad.public_model.to_json
    else
      { :encrypt_method => pad.encrypt_method, :text => pad.decrypt_text(params[:password]) }.to_json
    end
  end

  # Creates and new pad and returns the hash_id
  post "/pads" do
    pad = Pad.new(params)
    pad.save
    if params[:file]
      file_params = params[:file]
      new_path = "/tmp/#{file_params[:filename]}"
      puts "  Received file size for #{file_params[:filename]}: #{File.size(file_params[:tempfile].path)}"
      puts "  Path: #{file_params[:tempfile].path}"
      FileUtils.mv(file_params[:tempfile].path, new_path)
    end
    content_type "application/json"
    { :hash_id => pad.hash_id.to_s }.to_json
  end

  post "/cron_job" do
    do_cron_job
  end

  post "/user" do
    User.new(:email => params[:email]).save
    ""
  end

  private

  # Renders the template with the base template which requires the template's coffee and scss file.
  def render_with_layout(template, *additional_js)
    script_tags = ""
    additional_js.each { |fileName| script_tags << "<script src='/js/#{fileName}'></script>" }
    erb :base, :locals => { :template => template, :script_tags => script_tags }
  end

  def do_cron_job
    if !defined?(@@last_cron_run).nil? && @@last_cron_run > (Time.now - 3600)
      return "cron job last ran on #{@@last_cron_run} and wasn't run again."
    end
    @@last_cron_run = Time.now
    `rake delete_old_pads`
  end
end
  