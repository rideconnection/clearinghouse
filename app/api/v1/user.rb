module Clearinghouse
  class API_v1 < Grape::API
    helpers API_Authentication
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do
      params do
        use :authentication_params
      end

      namespace :users do
        desc "Get a list of users belonging to this provider"
        get do
          present current_provider.users, with: Clearinghouse::Entities::V1::User
        end

        params do
          requires :id, :type => Integer, :desc => 'User ID.'
        end
        scope :requires_id do
          desc "Get a specific user"
          get ':id' do
            present current_provider.users.find(params[:id]), with: Clearinghouse::Entities::V1::User
          end

          desc "Update a specific user"
          put ':id' do
            user = current_provider.users.find(params[:id])

            if params[:user] && params[:user].try(:[], :password).blank?
              params[:user].delete("password")
              params[:user].delete("password_confirmation")
            end

            if user.update_attributes(params[:user])
              present user, with: Clearinghouse::Entities::V1::User
            else
              error!({message: "Could not update user", errors: user.errors}, 422)
            end
          end

          desc "Activates a specific user"
          put ':id/activate' do
            user = current_provider.users.find(params[:id])

            if user.update_attribute(:active, true)
              present user, with: Clearinghouse::Entities::V1::User
            else
              error!({message: "Could not activate user", errors: user.errors}, 422)
            end
          end

          desc "Activates a specific user"
          put ':id/deactivate' do
            user = current_provider.users.find(params[:id])

            if user.update_attribute(:active, false)
              present user, with: Clearinghouse::Entities::V1::User
            else
              error!({message: "Could not deactivate user", errors: user.errors}, 422)
            end
          end
        end
      end

    end
  end
end
