require File.join(Dir.pwd, "lib", "db")
desc "Deletes pads where die time has passed - This task is called by the Heroku cron add-on"
task :delete_old_pads do
  puts "Cleaning old pads..."
  count = DB[:pads].filter('die_time < ?', Time.now).delete
  puts "done - deleted #{count} pads"
end