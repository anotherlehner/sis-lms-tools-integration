RailsAdmin.config do |config|
  config.asset_source = :sprockets

  config.authenticate_with do
    unless User.find_by(id: session[:user_id])&.admin?
      redirect_to main_app.lms_login_path, alert: "Administrator login required."
    end
  end

  config.current_user_method do
    User.find_by(id: session[:user_id])
  end

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end

  config.model User do
    list do
      exclude_fields :password_digest
    end

    show do
      exclude_fields :password_digest
    end

    edit do
      exclude_fields :password_digest
    end
  end
end
