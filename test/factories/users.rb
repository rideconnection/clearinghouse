# Read about factories at https://github.com/thoughtbot/factory_girl

# Creates a user that is a member of no provider.  Pass :provider to override
# this and associate the user with a provider.
FactoryGirl.define do
  factory :user do
    email {"user.#{Time.current.to_f}@clearinghouse.org"}
    password "password 1"
    password_confirmation { |u| u.password }
    provider
    
    # Roles
    factory :csr do
      role :name => :csr
    end
    factory :dispatcher do
      role :name => :dispatcher
    end
    factory :scheduler do
      role :name => :scheduler
    end
    factory :provider_admin do
      role :name => :provider_admin
    end
    factory :site_admin do
      role :name => :site_admin
    end
  end
end
