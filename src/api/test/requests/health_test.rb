ENV["RAILS_ENV"] = "test"
require_relative "../../config/environment"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"

class HealthTest < Minitest::Test
  include Rack::Test::Methods
  def app = Rails.application

  def test_liveness_works_without_database
    get "/up"
    assert_equal 200, last_response.status
    assert_equal({ "status" => "ok" }, JSON.parse(last_response.body))
  end

  def test_missing_database_readiness_is_sanitized
    original = ENV.delete("TEST_DATABASE_URL")
    get "/health"
    assert_equal 503, last_response.status
    assert_equal({ "status" => "unavailable", "database" => "unavailable", "worker" => "unverified" }, JSON.parse(last_response.body))
  ensure
    ENV["TEST_DATABASE_URL"] = original if original
  end

  def test_connection_error_is_sanitized
    original = ENV["TEST_DATABASE_URL"]
    ENV["TEST_DATABASE_URL"] = "postgres://synthetic.invalid/synthetic"
    failure = -> { raise ActiveRecord::ConnectionNotEstablished, "sensitive connection detail" }
    ActiveRecord::Base.stub(:connection_pool, failure) do
      get "/health"
      assert_equal 503, last_response.status
      refute_includes last_response.body, "sensitive"
    end
  ensure
    ENV["TEST_DATABASE_URL"] = original
  end

  def test_fixture_flag_cannot_open_production
    original = ENV["ENABLE_DIAGNOSTIC_FIXTURES"]
    ENV["ENABLE_DIAGNOSTIC_FIXTURES"] = "1"
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      get "/fixtures/probes/example"
      assert_equal 403, last_response.status
    end
  ensure
    ENV["ENABLE_DIAGNOSTIC_FIXTURES"] = original
  end

  def test_business_api_and_fixture_closed_by_default
    get "/courses"
    assert_equal 403, last_response.status
    get "/fixtures/probes/example"
    assert_equal 403, last_response.status
  end
end
