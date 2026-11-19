class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
  end

  def create
    user = User.find_by(username: params[:username].to_s.strip.downcase)

    if user && params[:password].present? && user.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome, #{user.first_name}."
    else
      flash.now[:alert] = "Username or password is incorrect."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to lms_login_path, notice: "You have signed out."
  end
end
