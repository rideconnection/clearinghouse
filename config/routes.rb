Clearinghouse::Application.routes.draw do
  devise_for :users

  resources :open_capacities
  resources :providers
  resources :trip_tickets do
    post 'search', :on=>:collection
  end
  scope '/admin' do
    root :to => "admin#index", :as => :admin
    resources :users do
      member do
        post '/activate' => 'users#activate'
        post '/deactivate' => 'users#deactivate'
      end
    end
  end

  match 'reports', :controller=>:reports, :action=>:index

  root :to => 'home#dashboard'
end
