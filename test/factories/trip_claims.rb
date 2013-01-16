# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trip_claim do
    association :claimant, factory: :provider
    status "Pending"
    rate "1.23"
    claimant_service_id 1
    trip_ticket
  end
end
