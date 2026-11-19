class SessionsController < ApplicationController
  def new
  end

  def create
    person = Person.find_by(username: params[:username])

    if person && person.password == params[:password]
      session[:person_id] = person.id
      redirect_to rails_admin_path
    else
      flash.now[:alert] = "Invalid username or password"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:person_id)
    redirect_to sis_login_path, notice: "Logged out"
  end
end
