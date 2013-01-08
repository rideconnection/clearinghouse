class TripTicket < ActiveRecord::Base
  belongs_to :originator, :foreign_key => :origin_provider_id
  belongs_to :claimant,   :foreign_key => :claimant_provider_id

  has_one :customer_address, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  has_one :pick_up_location, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  has_one :drop_off_location, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  
  has_one :mobility_type
  has_many :trip_claims
  has_one :trip_result
  
  SCHEDULING_PRIORITY = {
    "pickup"  => "Pickup",
    "dropoff" => "Drop-off"
  }
  
  attr_accessible :allowed_time_variance, :appointment_time,
   :approved_claim_id, :claimant_customer_id, :claimant_provider_id,
   :claimant_trip_id, :customer_address_attributes, :customer_address_id,
   :customer_boarding_time, :customer_deboarding_time, :customer_dob,
   :customer_emergency_phone, :customer_ethnicity_id, :customer_first_name,
   :customer_impairment_description, :customer_information_withheld,
   :customer_last_name, :customer_middle_name, :customer_notes,
   :customer_primary_language, :customer_primary_phone,
   :customer_seats_required, :drop_off_location_attributes,
   :drop_off_location_id, :earliest_pick_up_time, :mobility_type_id,
   :num_attendants, :num_guests, :origin_customer_id, :origin_provider_id,
   :origin_trip_id, :pick_up_location_attributes, :pick_up_location_id,
   :requested_drop_off_time, :requested_pickup_time, :scheduling_priority,
   :trip_notes, :trip_purpose_code, :trip_purpose_description
  
  accepts_nested_attributes_for :customer_address, :pick_up_location, :drop_off_location

  audited
  
  validates_presence_of :customer_dob, :customer_ethnicity_id,
    :customer_first_name, :customer_last_name, :customer_primary_phone,
    :customer_seats_required, :origin_provider_id, :requested_drop_off_time,
    :requested_pickup_time
  
  validates :customer_information_withheld, :inclusion => { :in => [true, false] }
  validates :scheduling_priority, :inclusion => { :in => SCHEDULING_PRIORITY.keys }
  
  after_initialize do
    if self.new_record?
      self.allowed_time_variance = -1
      self.customer_boarding_time = 0
      self.customer_deboarding_time = 0
      self.customer_seats_required = 1
      self.num_attendants = 0
      self.num_guests = 0
    end
  end
  
  def customer_full_name
    [customer_first_name, customer_middle_name, customer_last_name].compact.reject(&:blank?).join(" ")
  end
end