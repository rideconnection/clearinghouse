# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :location do
    address_1 '123 Main St'
    city 'Portland'
    state 'OR'
    zip '97210'
    phone_number '123-456-7890'
    common_name 'Common Name'
    jurisdiction 'Jurisdiction'
  end
end
