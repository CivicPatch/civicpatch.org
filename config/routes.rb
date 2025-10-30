Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    resources :representatives, only: [ :index ] do
      collection do
        post :search
      end
    end
  end

  get "map/details" => "map#details"
  get "map#index" => "map#index", as: :map_index 
  get "map/lat_long" => "map#lat_long"
  get "map/municipality_boundaries" => "map#municipality_boundaries"
  get "progress" => "map#progress", as: :progress
  get "address_search" => "pages#address_search", as: :address_search 
  root "pages#home"
end
