# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trip_claim do
    association :claimant, factory: :provider
    status :pending
    claimant_service_id 1
    trip_ticket
    proposed_pickup_time { DateTime.now }
    proposed_fare "$1.23"
  end
end
