module Clearinghouse
  class API_v1 < Grape::API
    helpers APIHelpers
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do

      namespace :provider do
        desc "Get details about the current provider"
        get do
          present current_provider, with: Clearinghouse::Entities::V1::Provider
        end

        desc "Update the current provider (currently limited to primary_contact_email only)"
        put do
          # currently limited to primary_contact_email only
          allowed_params = params[:provider].select{|k,v| [:primary_contact_email].include?(k.to_sym) }
          if current_provider.update_attributes(allowed_params)
            present current_provider, with: Clearinghouse::Entities::V1::Provider
          else
            error!({message: "Could not update provider", errors: current_provider.errors}, 422)
          end
        end
      end

    end
  end
end
