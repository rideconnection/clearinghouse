class TripTicket < ActiveRecord::Base
  belongs_to :provider, :foreign_key => :origin_provider_id
  belongs_to :provider, :foreign_key => :claimant_provider_id

  has_one :location, :foreign_key => :customer_address_id
  has_one :location, :foreign_key => :pick_up_location_id
  has_one :location, :foreign_key => :drop_off_location_id
  has_one :mobility_type
  has_many :trip_ticket_events
  has_many :trip_claims
  has_one :trip_result

  attr_accessible :allowed_time_variance, :appointment_time,
    :approved_claim_id, :claimant_customer_id, :claimant_trip_id,
    :customer_address_id, :customer_boarding_time, :customer_deboarding_time,
    :customer_dob, :customer_emergency_phone,
    :customer_impairment_description, :customer_information_withheld,
    :customer_name, :customer_notes, :customer_primary_phone,
    :customer_seats_required, :drop_off_location_id, :earliest_pick_up_time,
    :mobility_type_id, :num_attendants, :num_guests, :origin_customer_id,
    :origin_trip_id, :pick_up_location_id, :scheduling_priority, :trip_notes,
    :trip_purpose_code, :trip_purpose_description

  audited
end
