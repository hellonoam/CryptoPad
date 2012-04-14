require "sequel"
# DB = Sequel.connect(ENV["DATABASE_URL"] || "sqlite://db/dev.sqlite")
DB = Sequel.connect(ENV["DATABASE_URL"] || "postgres://localhost/pad.db")