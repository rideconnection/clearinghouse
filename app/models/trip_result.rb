class TripResult < ActiveRecord::Base
  belongs_to :trip_ticket
  has_one :trip_claim

  attr_accessible :actual_drop_off_time, :actual_pick_up_time, :base_fare,
    :billable_mileage, :driver_id, :extra_securement_count, :fare, :fare_type,
    :miles_travelled, :odometer_end, :odometer_start, :outcome, :rate,
    :rate_type, :trip_claim_id, :trip_ticket_id, :vehicle_id, :vehicle_type

  validates :trip_ticket_id, 
    :presence => true,
    :uniqueness => true

  validates :outcome, 
    :presence => true,
    :inclusion => { :in => ["Completed", "No-Show", "Cancelled"] }

  validate :ensure_trip_ticket_is_approved

  private

  def ensure_trip_ticket_is_approved
    unless trip_ticket.try(:approved?)
      errors.add(:trip_ticket, "must be approved")
    end
  end
end
