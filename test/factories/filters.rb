# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :filter do
    association :user
    name 'customer name bob'
    data({"customer_name" => "Bob"})
  end
end
