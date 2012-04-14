require "sqlite3"
require "sequel"
DB = Sequel.connect("sqlite://db/dev.sqlite")