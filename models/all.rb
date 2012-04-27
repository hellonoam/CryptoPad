Dir.open(File.join(Dir.pwd, "models")).each do |filename|
  require File.join(Dir.pwd, "models", filename) unless [".", ".."].index(filename)
end