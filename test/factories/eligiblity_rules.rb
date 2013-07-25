# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :eligibility_rule do
    eligibility_requirement
    trip_field 'customer_dob'
    comparison_type 'greater_than'
    comparison_value '59'
  end
end
