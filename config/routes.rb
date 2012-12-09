require 'api'

Clearinghouse::Application.routes.draw do
  mount Clearinghouse::API => "/"
  
  devise_for :users

  resources :open_capacities
  resources :providers do
    post 'activate', :on => :member
    post 'deactivate', :on => :member
  end
  resources :trip_tickets do
    post 'search', :on=>:collection
  end
  resources :users do
    member do
      post '/activate' => 'users#activate'
      post '/deactivate' => 'users#deactivate'
    end
  end

  match 'admin', :controller=>:admin, :action=>:index
  match 'reports', :controller=>:reports, :action=>:index

  root :to => 'home#dashboard'
end
