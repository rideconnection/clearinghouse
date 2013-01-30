# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trip_ticket do
    customer_dob "2012-01-01"
    customer_information_withheld false
    customer_first_name "First"
    customer_last_name "Last"
    customer_primary_phone "555-555-5555"
    customer_seats_required 1
    requested_drop_off_time { Time.now }
    requested_pickup_time { Time.now }
    scheduling_priority "pickup"
    association :originator, :factory => :provider
    association :customer_address, :factory => :location
    association :pick_up_location, :factory => :location
    association :drop_off_location, :factory => :location
  end
end
