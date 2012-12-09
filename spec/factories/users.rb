# Read about factories at https://github.com/thoughtbot/factory_girl

# Creates a user that is a member of no provider.  Pass :provider to override
# this and associate the user with a provider.
FactoryGirl.define do
  factory :user do
    ignore do
      provider nil
    end
    email {"user.#{Time.current.to_f}@clearinghouse.org"}
    password "password 1"
    password_confirmation { |u| u.password }
    after :create do |user, evaluator|
      if !evaluator.provider.nil?
        user.provider = evaluator.provider
      end
    end
  end
end
