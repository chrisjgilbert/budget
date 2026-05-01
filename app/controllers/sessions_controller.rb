class SessionsController < ApplicationController
  skip_before_action :require_auth, only: %i[new create]

  rate_limit to: 5, within: 3.minutes, only: :create,
             with: -> { redirect_to login_path, alert: "Too many attempts. Try again shortly." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    if password_matches?(params[:password])
      cookies.signed.permanent[:authenticated] = {
        value: "1",
        httponly: true,
        same_site: :lax
      }
      redirect_to root_path
    else
      flash.now[:alert] = "Wrong password."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    cookies.delete(:authenticated)
    redirect_to login_path
  end

  private

  def password_matches?(pw)
    return false if pw.blank?
    return false if stored_password_hash.blank?
    BCrypt::Password.new(stored_password_hash) == pw
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def stored_password_hash
    Rails.application.credentials.app_password_hash!
  end
end
