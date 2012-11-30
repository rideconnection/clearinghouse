# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email {"user.#{Time.current.to_f}@clearinghouse.org"}
    password "password 1"
    password_confirmation { |u| u.password }
    association :provider
  end
end
