Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  get "login", to: "sessions#new", as: :sis_login
  post "login", to: "sessions#create", as: :sis_login_post
  delete "logout", to: "sessions#destroy", as: :logout
  get "up" => "rails/health#show", as: :rails_health_check

  post "sync/gradebook", to: "api/sync#gradebook"
  post "ims/oneroster/v1p2/oauth/token", to: "api/ims/oneroster/v1p2/oauth_tokens#create"
  get "ims/oneroster/v1p2/orgs", to: "api/ims/oneroster/v1p2/rostering#organizations"
  get "ims/oneroster/v1p2/courses", to: "api/ims/oneroster/v1p2/rostering#courses"
  get "ims/oneroster/v1p2/classes", to: "api/ims/oneroster/v1p2/rostering#classes"
  get "ims/oneroster/v1p2/users", to: "api/ims/oneroster/v1p2/rostering#users"
  get "ims/oneroster/v1p2/enrollments", to: "api/ims/oneroster/v1p2/rostering#enrollments"
  root "sessions#new"
end
