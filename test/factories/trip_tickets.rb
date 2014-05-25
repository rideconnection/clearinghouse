# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :trip_ticket do
    rescinded false
    customer_dob "2012-01-01"
    customer_information_withheld false
    customer_first_name "First"
    customer_last_name "Last"
    customer_primary_phone "555-555-5555"
    customer_seats_required 1
    origin_customer_id "ABC123"
    appointment_time { Time.zone.now }
    requested_drop_off_time { (appointment_time - 15.minutes).to_s(:time_utc) }
    requested_pickup_time { (appointment_time - 45.minutes).to_s(:time_utc) }
    scheduling_priority "pickup"
    association :originator, :factory => :provider
    association :pick_up_location, :factory => :location
    association :drop_off_location, :factory => :location
  end
end
