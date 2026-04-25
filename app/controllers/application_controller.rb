class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_auth

  helper_method :authenticated?

  private

  def authenticated?
    cookies.signed[:authenticated] == "1"
  end

  def require_auth
    redirect_to login_path unless authenticated?
  end
end
