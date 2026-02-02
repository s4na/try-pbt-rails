Rails.application.routes.draw do
  # Authentication
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # User registration
  get  "signup", to: "users#new"
  post "signup", to: "users#create"

  # Posts (blog articles)
  resources :posts do
    resources :comments, only: [ :create, :destroy ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "posts#index"
end
