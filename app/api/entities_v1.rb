module Clearinghouse
  module Entities
    class User < Grape::Entity
      expose :id, :active, :email, :name, :phone, :roles, :title
    end
    
    class Provider < Grape::Entity
      expose :name
    end
  end
end
