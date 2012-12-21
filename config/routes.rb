require 'api'

Clearinghouse::Application.routes.draw do
  resources :trip_tickets

  mount Clearinghouse::API => "/"
  
  devise_for :users

  resources :open_capacities
  resources :providers do
    member do
      post 'activate'
      post 'deactivate'
      get  'keys'
      post 'reset_keys'
    end
    resources :services, :except => [ :index, :show, :destroy ]
  end
  resources :trip_tickets do
    post 'search', :on => :collection
  end
  resources :users do
    post 'activate', :on => :member
    post 'deactivate', :on => :member
  end

  match 'admin', :controller => :admin, :action => :index
  match 'reports', :controller => :reports, :action => :index

  root :to => 'home#dashboard'
end