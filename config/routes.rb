Gni::Application.routes.draw do

  resources :data_sources, only: [:index, :show]
  resources :name_strings, only: [:index, :show]
  resources :name_string_indices, only: [:index]
  resources :name_resolvers, only: [:index, :show, :create]
  resources :nomenclatural_codes, only: [:index]
  
  match '/:id' => 'high_voltage/pages#show', as: :static, via: :get

  root to: 'home#index'

end
