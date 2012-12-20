require 'entities_v1'

module Clearinghouse
  class API_v1 < Grape::API
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do
      namespace :originator do
        desc "Says hello"
        get :hello do
          "Hello, originator!"
        end
      end
      
      namespace :claimant do
        desc "Says hello"
        get :hello do
          "Hello, claimant!"
        end
      end
      
      namespace :users do
        desc "Get a list of users belonging to this provider"
        get do
          present current_provider.users, with: Clearinghouse::Entities::User
        end

        params do
          requires :id, :type => Integer, :desc => 'User ID.'
        end
        desc "Get a specific user"
        get :show do
          present current_provider.users.find(params[:id]), with: Clearinghouse::Entities::User
        end
      end
      
      namespace :provider do
        desc "Says hello"
        get :hello do
          "Hello, claimant!"
        end
      end
    end
  end
end
