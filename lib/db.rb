require "sequel"
DB = Sequel.connect(ENV["DATABASE_URL"] || "sqlite://db/dev.sqlite")