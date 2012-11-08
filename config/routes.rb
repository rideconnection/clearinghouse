Clearinghouse::Application.routes.draw do
  resources :open_capacities
  resources :providers
  resources :trip_tickets do
    post 'search', :on=>:collection
  end
  resources :users do
    get 'account', :on=>:collection # TODO: This will be on a single user
    post 'logout', :on=>:collection # TODO: Hook up to Devise
  end

  match 'reports', :controller=>:reports, :action=>:index

  root :to => 'home#dashboard'
end
