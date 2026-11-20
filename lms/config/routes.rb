Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  get "login", to: "sessions#new", as: :lms_login
  post "login", to: "sessions#create", as: :lms_login_create
  delete "logout", to: "sessions#destroy", as: :logout
  get "up" => "rails/health#show", as: :rails_health_check

  get ".well-known/openid-configuration", to: "lti/platform#openid_configuration"
  get "lti/jwks", to: "lti/platform#jwks"
  get "lti/authorize", to: "lti/platform#authorize"
  post "lti/oauth/token", to: "lti/oauth#create"
  get "lti/ags/line_items/:activity_id/sections/:section_id", to: "lti/ags#line_item"
  post "lti/ags/line_items/:activity_id/sections/:section_id/scores", to: "lti/ags#create_score"

  post "sync/roster", to: "api/sync#roster"
  post "ims/oneroster/v1p2/oauth/token", to: "api/ims/oneroster/v1p2/oauth_tokens#create"
  get "ims/oneroster/v1p2/lineItems", to: "api/ims/oneroster/v1p2/gradebook#line_items"
  get "ims/oneroster/v1p2/results", to: "api/ims/oneroster/v1p2/gradebook#results"

  resources :courses, only: [] do
    resources :sections, only: :show do
      resources :activities, only: %i[create update destroy] do
        get :launch, on: :member, to: "lti/launches#create"
        patch :complete, on: :member
        collection do
          post :create_tool
        end
      end
      resource :gradebook, only: %i[show update], controller: "gradebooks"
    end
  end

  root "home#show"
end
