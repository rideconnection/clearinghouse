class TripTicket < ActiveRecord::Base
  belongs_to :originator, :class_name => :Provider, :foreign_key => :origin_provider_id
  belongs_to :claimant,   :class_name => :Provider, :foreign_key => :claimant_provider_id

  has_one :customer_address, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  has_one :pick_up_location, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  has_one :drop_off_location, :class_name => :Location, :as => :addressable,
          :validate => true, :dependent => :destroy
  
  has_many :trip_claims, :dependent => :destroy
  has_one :trip_result, :dependent => :destroy
  
  SCHEDULING_PRIORITY = {
    "pickup"  => "Pickup",
    "dropoff" => "Drop-off"
  }
  
  attr_accessible :allowed_time_variance, :appointment_time,
   :approved_claim_id, :claimant_customer_id, :claimant_provider_id,
   :claimant_trip_id, :customer_address_attributes, :customer_address_id,
   :customer_boarding_time, :customer_deboarding_time, :customer_dob,
   :customer_emergency_phone, :customer_ethnicity, :customer_first_name,
   :customer_impairment_description, :customer_information_withheld,
   :customer_last_name, :customer_middle_name, :customer_notes,
   :customer_primary_language, :customer_primary_phone,
   :customer_seats_required, :drop_off_location_attributes,
   :drop_off_location_id, :earliest_pick_up_time,
   :num_attendants, :num_guests, :origin_customer_id, :origin_provider_id,
   :origin_trip_id, :pick_up_location_attributes, :pick_up_location_id,
   :requested_drop_off_time, :requested_pickup_time, :scheduling_priority,
   :trip_notes, :trip_purpose_code, :trip_purpose_description,
   :customer_identifiers, :customer_mobility_impairments
  
  accepts_nested_attributes_for :customer_address, :pick_up_location, :drop_off_location

  audited
  
  validates_presence_of :customer_dob, :customer_first_name, :customer_last_name, 
    :customer_primary_phone, :customer_seats_required, :origin_provider_id, 
    :requested_drop_off_time, :requested_pickup_time
  
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
    [customer_first_name, customer_middle_name, customer_last_name].reject(&:blank?).join(" ")
  end
  
  # TODO - Add a timestamp or other field to enable us to quickly query
  # whether a ticket has been claimed or not. Currently we have to load all of
  # the associated trip_claims and iterate over those first. We should be able
  # able to do something like TripTicket.where('claimed_at IS NULL`) or
  # similar. This would also require refactoring of some code in the TripClaim
  # model to match (with the TripTicket field being the authoritative source.)
  def claimed?
    self.trip_claims.where(:status => TripClaim::STATUS[:approved]).count > 0
  end
  
  def claimable_by?(user)
    !self.claimed? && (user.has_admin_role? || !self.includes_claim_from?(user.provider))
  end
  
  def includes_claim_from?(provider)
    self.trip_claims.where(:claimant_provider_id => provider.id).count > 0
  end
end
