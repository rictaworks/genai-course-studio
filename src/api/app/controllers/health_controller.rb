class HealthController < ApplicationController
  skip_before_action :deny_business_access
  def live
    render json: { status: "ok" }
  end
  def ready
    configured = ENV[Rails.env.test? ? "TEST_DATABASE_URL" : "DATABASE_URL"].present?
    available = configured && ActiveRecord::Base.connection_pool.with_connection { |connection| connection.select_value("SELECT 1") == 1 }
    render json: { status: available ? "ready" : "unavailable", database: available ? "ready" : "unavailable", worker: "unverified" }, status: available ? :ok : :service_unavailable
  rescue ActiveRecord::ActiveRecordError, PG::Error
    render json: { status: "unavailable", database: "unavailable", worker: "unverified" }, status: :service_unavailable
  end
end
