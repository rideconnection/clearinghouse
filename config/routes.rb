require 'api'

Clearinghouse::Application.routes.draw do

  mount Clearinghouse::API => "/"
  
  devise_for :users

  resources :open_capacities

  resources :provider_relationships, :except => :index do
    post 'activate'
  end

  resources :providers do
    member do
      post 'activate'
      post 'deactivate'
      get  'keys'
      post 'reset_keys'
    end
    resources :services, :except => [ :index, :show, :destroy ]
  end

  resources :trip_claims, :only => :index
  
  resources :trip_results

  resources :trip_tickets do
    post 'search', :on => :collection
    member do
      post 'rescind'
    end

    resources :trip_claims, :except => [:index] do
      member do
        post 'approve'
        post 'decline'
        post 'rescind'
      end
    end
    
    resources :trip_ticket_comments
  end

  resources :users do
    post 'activate', :on => :member
    post 'deactivate', :on => :member
  end

  match 'admin', :controller => :admin, :action => :index
  match 'reports', :controller => :reports, :action => :index

  root :to => 'home#dashboard'
end
