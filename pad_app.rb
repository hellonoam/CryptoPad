require "sinatra/base"
require "set"
require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "all")
require "coffee-script"
require "sass"
require "json"
require "mime/types"

class PadApp < Sinatra::Base

  set :public_folder, "public"
  enable :sessions
  enable :logging

  FILE_SIZE_LIMIT = 20 * 1000 * 1000 # 20 MB
  FILE_COUNT_LIMIT = 4

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
    render_with_layout(:create, ["sjcl.js", "crypto.coffee"])
  end

  get "/link/:hash_id" do
    port = (request.port == 80 || request.port == 443) ? "" : ":#{request.port}"
    pad_link = "#{request.scheme}://#{request.host}#{port}/pads/#{params[:hash_id]}"
    erb :link, :locals => { :pad_link => pad_link }
  end

  before "/pads/:hash_id*" do
    @pad = Pad[:hash_id => params[:hash_id]]
  end

  get "/pads/:hash_id" do
    no_password = @pad.pad_security_option.no_password
    render_with_layout(:pad, ["sjcl.js", "crypto.coffee"], { :no_password => no_password })
  end

  # Returns the pad's text if the password was correct
  get "/pads/:hash_id/authenticate" do
    halt 400, "invalid hash_id" if @pad.nil?
    halt 401, "incorrect password" unless @pad.correct_pass?(params[:password])

    # saving the password in the session for image decryption
    session[:password] = params[:password]
    session[:hash_id] = @pad.hash_id

    content_type "application/json"
    if @pad.encrypt_method == "client_side"
      @pad.public_model.to_json
    else
      { :encrypt_method => @pad.encrypt_method, :text => @pad.decrypt_text(params[:password]),
        :filenames => @pad.filenames }.to_json
    end
  end

  get "/pads/:hash_id/files/:filename" do
    redirect "/pads/#{params[:hash_id]}" if session[:hash_id] != params[:hash_id] || session[:hash_id].nil?
    pad_file = PadFile[:pad_id => @pad.id, :filename => params[:filename]]
    halt 404, "file not found" if pad_file.nil?
    # Silly Chrome cancels the request if it's application/octet-stream
    # So the type is determined by the extension if that fails it's set to text which seems to be successful
    # most of the time but not always. a PDF will fail when trying to download as text/plain
    content_type (MIME::Types.type_for(params[:filename]).first || "text/plain").to_s
    pad_file.get_decrypted_file(session[:password])
  end

  # Creates a new pad and returns the hash_id
  post "/pads" do
    pad = Pad.new(params)
    pad.save

    PadSecurityOption.new(JSON.parse(params[:securityOptions] || "{}").merge( :pad_id => pad.id )).save

    # Saving the files that were uploaded.
    (0...FILE_COUNT_LIMIT).each do |i|
      file_params = params["file#{i}"]
      break if file_params.nil?
      if File.size(file_params[:tempfile].path) > FILE_SIZE_LIMIT
        File.delete(file_params[:tempfile].path)
        next
      end
      pad_dir = "#{settings.root}/file_transfers/#{pad.hash_id}"
      new_path = "#{pad_dir}/#{file_params[:filename]}"
      puts "  Received file size for #{file_params[:filename]}: #{File.size(file_params[:tempfile].path)}"
      FileUtils.mkdir(pad_dir) unless File.exist?(pad_dir)

      PadFile.new( :pad_id => pad.id, :filename => file_params[:filename], :password => params[:password],
                   :temp_file_path => file_params[:tempfile].path, :new_file_path => new_path ).save
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

  helpers do
    def clippy(text, bgcolor='#FFFFFF')
      html = <<-EOF
        <div class="span1 clippy" style="position:relative; margin-top:25px">
          <img src="/flash/clippy.png" style="position:absolute">
          <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="110" height="16" id="clippy"
           scale="exactfit" style="opacity:0;position:absolute">
            <param name="movie" value="/flash/clippy.swf"/>
            <param name="allowScriptAccess" value="always" />
            <param name="quality" value="high" />
            <param name="scale" value="noscale" />
            <param NAME="FlashVars" value="text=#{text}">
            <param name="bgcolor" value="#{bgcolor}">
            <embed src="/flash/clippy.swf"
                 width="110"
                 height="16"
                 name="clippy"
                 quality="high"
                 scale="exactfit"
                 allowScriptAccess="always"
                 type="application/x-shockwave-flash"
                 pluginspage="http://www.macromedia.com/go/getflashplayer"
                 FlashVars="text=#{text}"
                 bgcolor="#{bgcolor}"
            />
          </object>
        </div>
      EOF
    end
  end

  private

  # Renders the template with the base template which requires the template's coffee and scss file.
  # Will add script tags on the template for the additional_js and pass the locals to the template.
  def render_with_layout(template, additional_js = [], locals = {})
    script_tags = ""
    additional_js.each { |fileName| script_tags << "<script src='/js/#{fileName}'></script>" }
    erb :base, :locals => locals.merge({ :template => template, :script_tags => script_tags })
  end

  def do_cron_job
    if !defined?(@@last_cron_run).nil? && @@last_cron_run > (Time.now - 3600)
      return "cron job last ran on #{@@last_cron_run} and wasn't run again."
    end
    @@last_cron_run = Time.now
    `rake delete_old_pads`
  end
end
  