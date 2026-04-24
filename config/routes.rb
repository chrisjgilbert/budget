Rails.application.routes.draw do
  get    "login",  to: "sessions#new",     as: :login
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  resources :months, only: %i[index show create] do
    resources :fields, only: %i[create update destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "months#index"
end
