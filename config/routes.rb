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
    resources :services, :except => [ :index, :show, :destroy ] do
      resources :eligibility_requirements, shallow: true
      resources :mobility_accommodations, shallow: true
    end
  end

  resources :trip_claims, :only => :dashboard
  
  resources :trip_tickets do
    post 'search', :on => :collection
    member do
      post 'rescind'
    end

    resources :trip_claims do
      member do
        post 'approve'
        post 'decline'
        post 'rescind'
      end
    end
    
    resources :trip_ticket_comments

    resource :trip_result

    resources :audits, :only => [ :index ]
  end

  resources :users do
    post 'activate', :on => :member
    post 'deactivate', :on => :member
  end

  resources :filters

  match 'admin', :controller => :admin, :action => :index
  match 'reports', :controller => :reports, :action => :index
  match "/admin/job_queue" => DelayedJobWeb, :anchor => false, :constraints => lambda { |request|
    request.env['warden'].authenticated? # are we authenticated?
    request.env['warden'].authenticate! # authenticate if not already
    request.env['warden'].user.has_admin_role? # Ensure site_admin role
  }
  
  root :to => 'trip_tickets#index'
end
