ENV["RAILS_ENV"] = "test"
require_relative "../lib/database_safety"
DatabaseSafety.verify_test!(ENV["TEST_DATABASE_URL"], ENV["DATABASE_URL"])
require_relative "../config/environment"
require "rails/test_help"
