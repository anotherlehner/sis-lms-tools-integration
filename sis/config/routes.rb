Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  get "login", to: "sessions#new", as: :sis_login
  post "login", to: "sessions#create", as: :sis_login_post
  delete "logout", to: "sessions#destroy", as: :logout
  get "up" => "rails/health#show", as: :rails_health_check
  root "sessions#new"
end
