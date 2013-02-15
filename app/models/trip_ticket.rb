class TripTicket < ActiveRecord::Base
  serialize :customer_identifiers, ActiveRecord::Coders::Hstore
  
  belongs_to :originator, :foreign_key => :origin_provider_id, :class_name => :Provider, :validate => true
  belongs_to :claimant, :foreign_key => :claimant_provider_id, :class_name => :Provider, :validate => true
  belongs_to :customer_address,  :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :pick_up_location,  :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :drop_off_location, :class_name => :Location, :validate => true, :dependent => :destroy
  
  has_many :trip_claims, :dependent => :destroy
  has_many :trip_ticket_comments, :dependent => :destroy
  has_one  :trip_result, :dependent => :destroy
  
  SCHEDULING_PRIORITY = {
    "pickup"  => "Pickup",
    "dropoff" => "Drop-off"
  }

  ETHNICITY_CHOICES = [
    'Hispanic origin', 
    'Not of Hispanic origin'
  ]

  RACE_CHOICES = [
    "American Indian or Alaskan Native",
    "Asian or Pacific Islander",
    "Black",
    "Hispanic",
    "White"
  ]

  ARRAY_FIELDS = {
    :customer_mobility_impairments => "Mobility Impairment",
    :customer_eligibility_factors => "Eligibility Factor",
    :customer_assistive_devices => "Assistive Device",
    :customer_service_animals => "Service Animal",
    :guest_or_attendant_service_animals => "Guest or Attendant Service Animal",
    :guest_or_attendant_assistive_devices => "Guest or Attendant Assistive Device",
    :trip_funders => "Trip Funder",
  }

  ARRAY_FIELD_NAMES = ARRAY_FIELDS.keys
  
  attr_accessible :allowed_time_variance, :appointment_time,
    :claimant_provider_id, :claimant_trip_id, :customer_address_attributes, 
    :customer_address_id, :customer_boarding_time, :customer_deboarding_time, 
    :customer_dob, :customer_emergency_phone, :customer_ethnicity, 
    :customer_first_name, :customer_impairment_description, 
    :customer_information_withheld, :customer_last_name, :customer_middle_name, 
    :customer_notes, :customer_primary_language, :customer_primary_phone, 
    :customer_race, :customer_seats_required, :drop_off_location_attributes,
    :drop_off_location_id, :earliest_pick_up_time,
    :num_attendants, :num_guests, :origin_customer_id, :origin_provider_id,
    :origin_trip_id, :pick_up_location_attributes, :pick_up_location_id,
    :requested_drop_off_time, :requested_pickup_time, :scheduling_priority,
    :trip_notes, :trip_purpose_description,
    :customer_identifiers, :customer_mobility_impairments, 
    :customer_eligibility_factors, :customer_assistive_devices, 
    :customer_service_animals, :guest_or_attendant_service_animals,
    :guest_or_attendant_assistive_devices, :trip_funders
  
  accepts_nested_attributes_for :customer_address, :pick_up_location, :drop_off_location

  audited
  
  validates_presence_of :customer_dob, :customer_first_name, :customer_last_name, 
    :customer_primary_phone, :customer_seats_required, :origin_customer_id, 
    :origin_provider_id, :requested_drop_off_time, :requested_pickup_time
  
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
      self.customer_identifiers = {}
    end
  end
  
  def customer_full_name
    [customer_first_name, customer_middle_name, customer_last_name].reject(&:blank?).join(" ")
  end
  
  def approved?
    TripTicket.unscoped.joins(:trip_claims).select('1').where('trip_tickets.id = ? AND trip_claims.status = ?', self.id, TripClaim::STATUS[:approved]).count > 0
  end
  
  def claimable_by?(user)
    !self.approved? && (user.has_admin_role? || !self.includes_claim_from?(user.provider))
  end
  
  def includes_claim_from?(provider)
    self.trip_claims.where(:claimant_provider_id => provider.id).count > 0
  end
  
  class << self
    def approved
      approved_trip_ticket_ids = select_approved_trip_ticket_ids
      where(:id => approved_trip_ticket_ids)
    end
    
    def unclaimed
      unclaimed_trip_ticket_ids = Array(TripTicket.unscoped.select('trip_tickets.id').joins('LEFT OUTER JOIN trip_claims ON trip_claims.trip_ticket_id = trip_tickets.id GROUP BY trip_tickets.id HAVING count(trip_claims.id) = 0').pluck('trip_tickets.id'))
      where(:id => unclaimed_trip_ticket_ids)
    end
    
    def unapproved
      unapproved_trip_ticket_ids = Array(TripTicket.unscoped.select('trip_tickets.id').joins('LEFT OUTER JOIN trip_claims ON trip_claims.trip_ticket_id = trip_tickets.id GROUP BY trip_tickets.id HAVING count(trip_claims.id) > 0').pluck('trip_tickets.id')) - select_approved_trip_ticket_ids
      where(:id => unapproved_trip_ticket_ids)
    end
    
    def filter_by_customer_name(customer_name)
      value = customer_name.strip.downcase
      sql, values = [], []
      [:customer_first_name, :customer_middle_name, :customer_last_name].each do |field|
        sql << fuzzy_string_search(field, value)
        values.push "%#{value}%", value, value, value, value, value, value
      end
      where(sql.join(' OR '), *values)
    end
    
    def filter_by_customer_address_or_phone(customer_address_or_phone)
      # We need to manually write our join here since there's a chance
      # we could be joining/filtering on multiple locations
      join = 'LEFT OUTER JOIN "locations" as "customer_address" ON "customer_address"."id" = "trip_tickets"."customer_address_id"'
      value = customer_address_or_phone.strip.downcase
      sql, values = [], []
      ['customer_address.address_1', 'customer_address.address_2'].each do |field|
        sql << fuzzy_string_search(field, value)
        values.push "%#{value}%", value, value, value, value, value, value
      end
      sql << "LOWER(customer_primary_phone) LIKE ?"
      sql << "LOWER(customer_emergency_phone) LIKE ?"
      values.push "%#{value}%", "%#{value}%"
      
      joins(join).where([sql.join(' OR '), *values])
    end
  
    def filter_by_pick_up_location(pick_up_location)
      # We need to manually write our join here since there's a chance
      # we could be joining/filtering on multiple locations
      join = 'LEFT OUTER JOIN "locations" as "pick_up_location" ON "pick_up_location"."id" = "trip_tickets"."pick_up_location_id"'
      value = pick_up_location.strip.downcase
      sql, values = [], []
      ['pick_up_location.address_1', 'pick_up_location.address_2'].each do |field|
        sql << fuzzy_string_search(field, value)
        values.push "%#{value}%", value, value, value, value, value, value
      end

      joins(join).where([sql.join(' OR '), *values])
    end
  
    def filter_by_drop_off_location(drop_off_location)
      # We need to manually write our join here since there's a chance
      # we could be joining/filtering on multiple locations
      join = 'LEFT OUTER JOIN "locations" as "drop_off_location" ON "drop_off_location"."id" = "trip_tickets"."drop_off_location_id"'
      value = drop_off_location.strip.downcase
      sql, values = [], []
      ['drop_off_location.address_1', 'drop_off_location.address_2'].each do |field|
        sql << fuzzy_string_search(field, value)
        values.push "%#{value}%", value, value, value, value, value, value
      end

      joins(join).where([sql.join(' OR '), *values])
    end
  
    def filter_by_originating_provider(originating_providers)
      where(:origin_provider_id => Array(originating_providers).map(&:to_i))
    end
  
    def filter_by_claiming_provider(claiming_providers)
      joins(:trip_claims).joins('LEFT OUTER JOIN "providers" as "claimants" ON "claimants"."id" = trip_claims.claimant_provider_id').where('claimants.id IN (?)', Array(claiming_providers).map(&:to_i))
    end
  
    def filter_by_claim_status(status)
      case status.to_sym
      when :unclaimed
        unclaimed
      when :approved
        approved
      when :unapproved
        unapproved
      end
    end
  
    private
    
    def select_approved_trip_ticket_ids
      Array(TripTicket.unscoped.select('DISTINCT trip_tickets.id').joins(:trip_claims).where('trip_claims.status = ?', TripClaim::STATUS[:approved]).pluck('trip_tickets.id'))
    end
  
    def fuzzy_string_search(field, value)
      "(LOWER(%s) LIKE ? OR (
        (dmetaphone(?) <> '' OR dmetaphone_alt(?) <> '') AND (
        dmetaphone(%s) = dmetaphone(?) OR 
        dmetaphone(%s) = dmetaphone_alt(?) OR
        dmetaphone_alt(%s) = dmetaphone(?) OR 
        dmetaphone_alt(%s) = dmetaphone_alt(?))))" % [field, field, field, field, field]
    end
  end
end
