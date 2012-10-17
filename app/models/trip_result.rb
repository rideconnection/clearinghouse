class TripResult < ActiveRecord::Base
  belongs_to :trip_ticket
  has_one :trip_claim

  attr_accessible :actual_drop_off_time, :actual_pick_up_time, :base_fare,
    :billable_mileage, :driver_id, :extra_securements_used, :fare, :fare_type,
    :miles_travelled, :odometer_end, :odometer_start, :outcome, :rate,
    :rate_type, :trip_claim_id, :trip_ticket_id, :vehicle_id, :vehicle_type
end
