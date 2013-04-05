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

  CUSTOMER_IDENTIFIER_ARRAY_FIELDS = {
    :customer_mobility_impairments => "Mobility Impairment",
    :customer_eligibility_factors => "Eligibility Factor",
    :customer_assistive_devices => "Assistive Device",
    :customer_service_animals => "Service Animal",
    :guest_or_attendant_service_animals => "Guest or Attendant Service Animal",
    :guest_or_attendant_assistive_devices => "Guest or Attendant Assistive Device",
    :trip_funders => "Trip Funder",
  }

  CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES = CUSTOMER_IDENTIFIER_ARRAY_FIELDS.keys
  
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
    :trip_notes, :trip_purpose_description, :trip_result_attributes,
    :customer_identifiers, :customer_mobility_impairments, 
    :customer_eligibility_factors, :customer_assistive_devices, 
    :customer_service_animals, :guest_or_attendant_service_animals,
    :guest_or_attendant_assistive_devices, :trip_funders,
    :provider_white_list, :provider_black_list
  
  accepts_nested_attributes_for :customer_address, :pick_up_location, :drop_off_location, :trip_result

  audited
  
  validates_presence_of :customer_dob, :customer_first_name, :customer_last_name, 
    :customer_primary_phone, :customer_seats_required, :origin_customer_id, 
    :origin_provider_id, :requested_drop_off_time, :requested_pickup_time, 
    :appointment_time
  
  validates :customer_information_withheld, :inclusion => { :in => [true, false] }
  validates :scheduling_priority, :inclusion => { :in => SCHEDULING_PRIORITY.keys }
  
  validate do |trip_ticket|
    if trip_ticket.provider_white_list.present? && trip_ticket.provider_black_list.present?
      trip_ticket.errors[:provider_black_list] << "cannot be used with a white list"
    end
    
    if trip_ticket.provider_white_list.try(:any?) && !trip_ticket.provider_white_list.inject(true){|bool,element| bool && element.is_integer? }
      trip_ticket.errors[:provider_white_list] << "must be an array of integers"
    end
    
    if trip_ticket.provider_black_list.try(:any?) && !trip_ticket.provider_black_list.inject(true){|bool,element| bool && element.is_integer? }
      trip_ticket.errors[:provider_black_list] << "must be an array of integers"
    end
    
    if trip_ticket.provider_white_list.try(:any?) && trip_ticket.provider_white_list.include?(trip_ticket.origin_provider_id)
      trip_ticket.errors[:provider_white_list] << "cannot include the originating provider"
    end
    
    if trip_ticket.provider_black_list.try(:any?) && trip_ticket.provider_black_list.include?(trip_ticket.origin_provider_id)
      trip_ticket.errors[:provider_black_list] << "cannot include the originating provider"
    end
  end
  
  after_initialize do
    if self.new_record?
      self.allowed_time_variance = -1   if self.allowed_time_variance.nil?
      self.customer_boarding_time = 0   if self.customer_boarding_time.nil?
      self.customer_deboarding_time = 0 if self.customer_deboarding_time.nil?
      self.customer_seats_required = 1  if self.customer_seats_required.nil?
      self.num_attendants = 0           if self.num_attendants.nil?
      self.num_guests = 0               if self.num_guests.nil?
      self.customer_identifiers = {}    if self.customer_identifiers.nil?
    end
  end
  
  def make_result_for_form
    can_create_new_result? ? build_trip_result : self.trip_result
  end
  
  def can_create_or_edit_result?
    self.trip_result || can_create_new_result?
  end

  def can_create_new_result?
    test_result = TripResult.new(:outcome => "Completed")
    test_result.trip_ticket = self
    test_result.valid?
  end

  def customer_full_name
    [customer_first_name, customer_middle_name, customer_last_name].reject(&:blank?).map(&:strip).join(" ")
  end
  
  def seats_required
    "+ #{[num_attendants, customer_seats_required, num_guests].reject(&:blank?).sum}"
  end
  
  def ethnicity_and_race
    vals = [customer_race, customer_ethnicity].reject(&:blank?)
    
    case vals.size
    when 2
      "#{vals[0]} (#{vals[1]})"
    when 1
      vals[0]
    else
      ""
    end
  end
  
  def approved_claim
    trip_claims.detect{ |claim| claim.status == :approved}
  end

  def approved?
    TripTicket.unscoped.joins(:trip_claims).select('1').where('"trip_tickets"."id" = ? AND "trip_claims"."status" = ?', self.id, :approved).count > 0
  end
  
  def claimable_by?(user)
    !self.approved? && (user.has_admin_role? || !self.includes_claim_from?(user.provider))
  end
  
  def includes_claim_from?(provider)
    claims = self.trip_claims.where(:claimant_provider_id => provider.id)
    active = claims.where(["status NOT IN (?)", TripClaim::INACTIVE_STATUS])
    active.count > 0
  end
  
  class << self
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
      sql << "LOWER(customer_primary_phone) LIKE LOWER(?)"
      sql << "LOWER(customer_emergency_phone) LIKE LOWER(?)"
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
      joins(:trip_claims).joins('LEFT OUTER JOIN "providers" as "claimants" ON "claimants"."id" = "trip_claims"."claimant_provider_id"').where('"claimants"."id" IN (?)', Array(claiming_providers).map(&:to_i))
    end
  
    def filter_by_claim_status(status)
      case status.to_sym
      when :unclaimed
        # Tickets which have no claims on them or which have only declined or rescinded claims
        where(:id => Array(TripTicket.unscoped.select('"trip_tickets"."id"').joins('LEFT JOIN "trip_claims" ON "trip_claims"."trip_ticket_id" = "trip_tickets"."id"').group('"trip_tickets"."id"').having('COUNT("trip_claims"."id") = 0 OR COUNT("trip_claims"."id") = SUM(CASE "status" WHEN ? THEN 1 WHEN ? THEN 1 ELSE 0 END)', *TripClaim::INACTIVE_STATUS).pluck('"trip_tickets"."id"')))
      when :approved
        # Tickets which have approved claims
        where(:id => Array(TripClaim.unscoped.select(:trip_ticket_id).group(:trip_ticket_id).having('SUM(CASE "status" WHEN ? THEN 1 ELSE 0 END) > 0', :approved).pluck(:trip_ticket_id)))
      when :pending
        # Tickets which have pending claims
        where(:id => Array(TripClaim.unscoped.select(:trip_ticket_id).group(:trip_ticket_id).having('SUM(CASE "status" WHEN ? THEN 1 ELSE 0 END) > 0', :pending).pluck(:trip_ticket_id)))
      end
    end
    
    def filter_by_seats_required(value_hash)
      range = [value_hash.try(:[], :min).to_i, value_hash.try(:[], :max).to_i].sort
      where('("num_attendants" + "customer_seats_required" + "num_guests") BETWEEN ? AND ?', range[0], range[1])
    end
  
    def filter_by_scheduling_priority(scheduling_priority)
      where(:scheduling_priority => scheduling_priority)
    end

    def filter_by_trip_time(datetime_start, datetime_end)
      where([
        '(TO_TIMESTAMP(CAST(DATE("appointment_time") as character varying(255)) || \' \' || CAST("requested_pickup_time" as character varying(255)), \'YYYY-MM-DD HH24:MI:SS.US\') BETWEEN ? AND ?)',
        '(TO_TIMESTAMP(CAST(DATE("appointment_time") as character varying(255)) || \' \' || CAST("requested_drop_off_time" as character varying(255)), \'YYYY-MM-DD HH24:MI:SS.US\') BETWEEN ? AND ?)'
      ].join(' OR '), datetime_start, datetime_end, datetime_start, datetime_end)
    end
  
    def filter_by_customer_identifiers(customer_identifier)
      # There's no way to query for specific values in an hstore, only on 
      # keys. So we convert it to an array and search it along with the rest 
      # of the array fields. Also, this from the postgres docs: 
      #   Tip: Arrays are not sets; searching for specific array elements can 
      #   be a sign of database misdesign. Consider using a separate table
      #   with a row for each item that would be an array element. This will 
      #   be easier to search, and is likely to scale better for a large
      #   number of elements.
      array_concat = (CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES + ["CAST(avals(customer_identifiers) || akeys(customer_identifiers) AS character varying[])"]).join(' || ')
      where("LOWER('||' || ARRAY_TO_STRING(#{array_concat}, '||') || '||') LIKE LOWER(?)", "%||%#{customer_identifier}%||%")
    end
  
    private
    
    def fuzzy_string_search(field, value)
      "(LOWER(%s) LIKE LOWER(?) OR (
        (dmetaphone(?) <> '' OR dmetaphone_alt(?) <> '') AND (
        dmetaphone(%s) = dmetaphone(?) OR 
        dmetaphone(%s) = dmetaphone_alt(?) OR
        dmetaphone_alt(%s) = dmetaphone(?) OR 
        dmetaphone_alt(%s) = dmetaphone_alt(?))))" % [field, field, field, field, field]
    end
  end
end
