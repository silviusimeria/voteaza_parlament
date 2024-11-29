Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  root "home#index"

  namespace :api do
    namespace :v1 do
      get "map", to: "map#index"
    end
  end

  resources :counties, only: [] do
    member do
      get "panel"
    end
  end

  get "termeni-si-conditii", to: "pages#terms"
  get 'voting-info', to: 'pages#voting_info', as: :voting_info
  get 'candidate-evaluation', to: 'pages#candidate_evaluation', as: :candidate_evaluation


  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  # config/routes.r
end
