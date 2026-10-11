class ProbesController < ApplicationController
  skip_before_action :deny_business_access
  before_action :require_fixture_access
  def create
    probe = EnqueueProbe.call(key: params[:key], outcome: params[:outcome])
    render json: probe.slice(:id, :status, :error_code), status: :accepted
  rescue ArgumentError, ActiveRecord::RecordInvalid
    render json: { error: "invalid_fixture" }, status: :unprocessable_entity
  rescue ActiveRecord::ActiveRecordError, ActiveJob::EnqueueError
    render json: { error: "database_unavailable" }, status: :service_unavailable
  end
  def show
    render json: DiagnosticProbe.find(params[:id]).slice(:id, :status, :error_code)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue ActiveRecord::ActiveRecordError
    render json: { error: "database_unavailable" }, status: :service_unavailable
  end
  private
  def require_fixture_access
    head :forbidden unless FixtureAccess.allowed?(Rails.env, ENV["ENABLE_DIAGNOSTIC_FIXTURES"])
  end
end
