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
        
        params do
          requires :id, :type => Integer, :desc => 'User ID.'
        end
        desc "Update a specific user"
        put :update do
          user = current_provider.users.find(params[:id])
          
          if params[:user] && params[:user].try(:[], :password).blank?
            params[:user].delete("password")
            params[:user].delete("password_confirmation")
          end
          
          if user.update_attributes(params[:user])
            present user, with: Clearinghouse::Entities::User
          else
            error!({message: "Could not authenticate #{source}", errors: user.errors}, status: :unprocessable_entity)
          end
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
