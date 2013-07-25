# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :eligibility_requirement do
    service
    boolean_type 'and'
  end
end
