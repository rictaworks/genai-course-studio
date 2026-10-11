class ApplicationController < ActionController::API
  before_action :deny_business_access
  def closed
    head :forbidden
  end
  private
  def deny_business_access
    head :forbidden
  end
end
