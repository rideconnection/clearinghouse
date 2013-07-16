class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message.gsub(/\bthis\b/, "that")
  end
  
  private
  
  def admins_only
    raise CanCan::AccessDenied unless current_user && current_user.has_any_role?([:site_admin, :provider_admin])
  end
end
