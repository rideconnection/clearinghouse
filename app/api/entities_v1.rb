module Clearinghouse
  module Entities
    module V1
      class User < Grape::Entity
        expose :id, :active, :email, :name, :phone, :roles, :title
      end
    
      class Provider < Grape::Entity
        expose :name, :primary_contact_id
        expose :primary_contact, :using => Clearinghouse::Entities::V1::User
        expose :address do |model, options|
          # See: https://github.com/intridea/grape/issues/75#issuecomment-7886125
          if model.address
            Clearinghouse::Entities::V1::Location.new(model.address).serializable_hash
          end
        end
      end
  
      class Location < Grape::Entity
        expose :address_1, :address_2, :city, :position, :state, :zip
      end
    end
  end
end
