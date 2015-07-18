# Read about factories at https://github.com/thoughtbot/factory_girl

# Creates a user that is a member of no provider.  Pass :provider to override
# this and associate the user with a provider.
FactoryGirl.define do
  factory :user do
    email {"user.#{Time.now.to_f}@clearinghouse.org"}
    password "Password 1"
    password_confirmation { |u| u.password }
    provider
    role { Role.find_or_create_by(name: "read_only") }
    active true
    confirmed_at 1.days.ago
  end
end
