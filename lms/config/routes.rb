Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  get "login", to: "sessions#new", as: :lms_login
  post "login", to: "sessions#create", as: :lms_login_create
  delete "logout", to: "sessions#destroy", as: :logout
  get "up" => "rails/health#show", as: :rails_health_check

  post "sync/roster", to: "api/sync#roster"
  post "ims/oneroster/v1p2/oauth/token", to: "api/ims/oneroster/v1p2/oauth_tokens#create"
  get "ims/oneroster/v1p2/lineItems", to: "api/ims/oneroster/v1p2/gradebook#line_items"
  get "ims/oneroster/v1p2/results", to: "api/ims/oneroster/v1p2/gradebook#results"

  resources :courses, only: [] do
    resources :sections, only: :show do
      resources :activities, only: %i[create update destroy] do
        patch :complete, on: :member
      end
      resource :gradebook, only: %i[show update], controller: "gradebooks"
    end
  end

  root "home#show"
end
