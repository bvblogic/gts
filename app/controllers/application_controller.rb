class ApplicationController < ActionController::Base 
  before_action :check_auth 
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: 500
  end

  protect_from_forgery with: :exception

  def authenticate_admin_user!
    redirect_to new_user_session_path unless user_signed_in?
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :role, :email, :password, :password_confirmation, :profile_picture) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:name, :role, :email, :password, :password_confirmation, :profile_picture) }
  end

  def check_auth
    unless user_signed_in?
      authenticate_or_request_with_http_basic do |username, password|
        resource = User.find_by_name(username)
        if resource.present?
          sign_in :user, resource
          redirect_to goals_path
        else
          new_user = User.create(name: username,
                                 email: "#{username}@bvblogic.com",
                                 role: 0)
          sign_in :user, new_user
          redirect_to goals_path
        end
      end
    end
  end
end
