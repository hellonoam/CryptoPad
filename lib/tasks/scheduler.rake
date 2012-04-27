require File.join(Dir.pwd, "lib", "db")
require File.join(Dir.pwd, "models", "all")
desc "Deletes pads where die time has passed - This task is called by the Heroku cron add-on"
task :delete_old_pads do
  puts "Cleaning old pads..."
  count = Pad.select(:pads__id).join(:pad_security_options, :pad_id => :id).
      filter('pad_security_options.die_time < ?', Time.now).destroy
  puts "done - deleted #{count} pads"
end