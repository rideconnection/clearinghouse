require 'trip_ticket_icons'
require 'notification_recipients'

class TripTicket < ActiveRecord::Base
  include TripTicketIcons
  include NotificationRecipients

  serialize :customer_identifiers, ActiveRecord::Coders::Hstore
  
  belongs_to :originator, :foreign_key => :origin_provider_id, :class_name => :Provider, :validate => true
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
    :customer_eligibility_factors => "Eligibility Factor",
    :customer_mobility_factors => "Mobility Factors",
    :customer_service_animals => "Service Animal",
    :trip_funders => "Trip Funder",
  }

  CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES = CUSTOMER_IDENTIFIER_ARRAY_FIELDS.keys

  CUSTOMER_IDENTIFIER_HSTORE_FIELDS = {
    :customer_identifiers => "Customer Identifiers",
  }

  CUSTOMER_IDENTIFIER_HSTORE_FIELD_NAMES = CUSTOMER_IDENTIFIER_HSTORE_FIELDS.keys

  attr_accessible :allowed_time_variance, :appointment_time,
    :customer_address_attributes, :customer_address_id,
    :customer_boarding_time, :customer_deboarding_time, :customer_dob,
    :customer_emergency_phone, :customer_ethnicity, :customer_first_name,
    :customer_impairment_description, :customer_information_withheld,
    :customer_last_name, :customer_middle_name, :customer_notes,
    :customer_primary_language, :customer_primary_phone, :customer_race,
    :customer_seats_required, :drop_off_location_attributes,
    :drop_off_location_id, :earliest_pick_up_time, :num_attendants,
    :num_guests, :origin_customer_id, :origin_provider_id, :origin_trip_id,
    :pick_up_location_attributes, :pick_up_location_id,
    :requested_drop_off_time, :requested_pickup_time, :scheduling_priority,
    :trip_notes, :trip_purpose_description, :trip_result_attributes,
    :customer_identifiers, :customer_service_level, :customer_eligibility_factors,
    :customer_mobility_factors, :customer_service_animals, :trip_funders,
    :provider_white_list, :provider_black_list, :expire_at, :expired
  
  accepts_nested_attributes_for :pick_up_location, :drop_off_location, :trip_result
  accepts_nested_attributes_for :customer_address, :reject_if => :all_blank

  audited

  acts_as_notifier do
    after_create do
      notify ->(opts){ partner_users(self, opts) }, method: :trip_created
    end
    after_save do
      notify ->(opts){ claimant_users(self, opts) }, if: proc{ rescinded_changed? && rescinded? }, method: :trip_rescinded
      notify ->(opts){ originator_and_claimant_users(self, opts) }, if: proc{ expired_changed? && expired? }, method: :trip_expired
    end
    after_update do
      notify ->(opts){ partner_users(self, opts) }, if: proc{
          !(rescinded_changed? && rescinded?) &&
          !(expired_changed? && expired?)
      }, method: :trip_updated, context: proc{ { trip_ticket: self, changes: changes } }
    end
  end

  validates_presence_of :customer_dob, :customer_first_name, :customer_last_name, 
    :customer_primary_phone, :customer_seats_required, :origin_customer_id, 
    :origin_provider_id
  
  validates :customer_information_withheld, :inclusion => { :in => [true, false] }
  validates :scheduling_priority, :inclusion => { :in => SCHEDULING_PRIORITY.keys }
  validate  :can_be_rescinded, on: :update, if: Proc.new { |trip| trip.rescinded? && trip.rescinded_changed? }

  # TODO - are these too restrictive for the data coming in the API?
  validates :customer_dob, :timeliness => {:type => :date}
  validates :requested_pickup_time, :timeliness => {:type => :time}
  validates :requested_drop_off_time, :timeliness => {:type => :time}
  validates :appointment_time, :timeliness => {:type => :datetime}
  validates :earliest_pick_up_time, :timeliness => {:type => :time, :allow_blank => true}
  validates :expire_at, :timeliness => {:type => :datetime, :allow_blank => true}
  
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
      self.allowed_time_variance    ||= -1
      self.customer_boarding_time   ||= 0
      self.customer_deboarding_time ||= 0
      self.customer_seats_required  ||= 1
      self.num_attendants           ||= 0
      self.num_guests               ||= 0
      self.customer_identifiers     ||= {}
    end
  end
  
  default_scope order('appointment_time ASC, created_at DESC')

  scope :originated_or_claimed_by, ->(provider) do
    subquery = TripClaim.unscoped.select(:trip_ticket_id).where(claimant_provider_id: provider.id).uniq.to_sql
    where('"trip_tickets"."origin_provider_id" = ? OR "trip_tickets"."id" IN (' << subquery << ')', provider.id)
      .reorder('')
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

  def status_for(resource)
    provider = if resource.is_a?(User) then resource.provider elsif resource.is_a?(Provider) then resource else Provider.new end
    provider.try(:id) == origin_provider_id ? originator_status(provider) : claimant_status(provider)
  end

  # does not add counts or specific claimant names, used for aggregating reports
  def simple_originator_status(provider)
    trip_status = status
    case trip_status
      when 'New', 'Rescinded', 'Expired'
        trip_status
      when 'Resolved'
        trip_result.try(:outcome) || 'Awaiting Result'
      when 'Active'
        if (claim = approved_claim).present?
          'Claim Approved'
        elsif (claim_count = trip_claims.where(status: 'pending').count) == 0
          'No Claims'
        else
          'Claims Pending'
        end
    end
  end

  def originator_status(provider)
    # The TripTicket.filter_by_ticket_status method is (unfortunately) tightly
    # coupled to this method. If this method changes, that method may need
    # to be updated as well.
    trip_status = status
    case trip_status
      when 'New', 'Rescinded', 'Expired'
        trip_status
      when 'Resolved'
        trip_result.try(:outcome) || 'Awaiting Result'
      when 'Active'
        if (claim = approved_claim).present?
          "#{claim.claimant.try(:name)} Approved"
        elsif (claim_count = trip_claims.where(status: 'pending').count) == 0
          'No Claims'
        else
          "#{claim_count} Claim#{claim_count == 1 ? '' : 's'} Pending"
        end
    end
  end

  def claimant_status(provider)
    # The TripTicket.filter_by_ticket_status method is (unfortunately) tightly
    # coupled to this method. If this method changes, that method may need
    # to be updated as well.
    trip_status = status
    if trip_status == 'New'
      'New'
    elsif trip_status == 'Expired'
      'Unavailable'
    else
      claim = claims_from(provider).reorder('created_at DESC').first
      if claim.try(:status) == :declined
        'Declined'
      else
        case trip_status
          when 'Rescinded'
            claim.present? ? 'Rescinded' : 'Unavailable'
          when 'Resolved'
            if claim.try(:status) == :approved
              trip_result.try(:outcome) || 'Awaiting Result'
            else
              'Unavailable'
            end
          when 'Active'
            if claim.try(:status) == :approved
              'Claimed'
            elsif claim.try(:status) == :pending
              'Claim Pending'
            else
              approved? ? 'Unavailable' : 'Available'
            end
        end
      end
    end
  end

  def status
    if new_record?
      'New'
    elsif rescinded?
      'Rescinded'
    elsif resolved?
      'Resolved'
    elsif expired?
      'Expired'
    else
      'Active'
    end
  end

  def resolved?
    (appointment_time.past? && approved?) || trip_result.present?
  end

  def approved_claim
    trip_claims.detect{ |claim| claim.status == :approved}
  end

  def approved?
    TripTicket.unscoped.joins(:trip_claims).select('1').where('"trip_tickets"."id" = ? AND "trip_claims"."status" = ?', self.id, :approved).count > 0
  end
  
  def claimable_by?(user)
    !self.expired? && !self.rescinded? && !self.approved? && (user.has_admin_role? || !self.includes_claim_from?(user.provider))
  end

  def claims_from(provider)
    trip_claims.where(:claimant_provider_id => provider.id)
  end

  def includes_claim_from?(provider)
    active = claims_from(provider).where(["status NOT IN (?)", TripClaim::INACTIVE_STATUS])
    active.count > 0
  end

  def rescindable?
    # any trip that does not have a result can be rescinded (if customer cancels, claims and approvals are irrelevant)
    !self.expired? && (trip_result.nil? || trip_result.new_record?)
  end

  def rescind!
    transaction do
      self.rescinded = true
      save!
      # rescind or cancel outstanding claims
      trip_claims.each do |claim|
        if claim.status == :pending
          claim.rescind!
        elsif claim.status == :approved
          self.create_trip_result(outcome: "Cancelled", trip_claim_id: claim.id)
        end
      end
    end
  end
  
  def activities_accessible_by(ability)
    audit_trail = audits_with_associated +
      trip_claims.accessible_by(ability).all +
      trip_ticket_comments.accessible_by(ability).all +
      [trip_result_for(ability)]
    
    audit_trail.compact.sort_by(&:created_at).reverse # Descending order
  end
  
  def audits_with_associated
    # The Audited gem includes methods to associate records of parent and child
    # records, but it doesn't work with polymorphic associations, so we'll 
    # mimic it here.
    # See: https://github.com/collectiveidea/audited#associated-audits
    (
      [audits.first] + 
      audits.where(action: 'update') +
      customer_address.audits.where(action: 'update') +
      pick_up_location.audits.where(action: 'update') +
      drop_off_location.audits.where(action: 'update')
    ).compact.sort_by(&:created_at).reverse # Descending order
  end

  protected

  def trip_result_for(ability)
    present = trip_result.present? && trip_result.id.present?
    if present && ability.can?(:read, trip_result) 
      trip_result
    end
  end

  def can_be_rescinded
    errors.add(:rescinded, "status may not be changed on resolved trip tickets") unless rescindable?
  end

  public

  class << self
    def filter_by_customer_name(customer_name)
      parts = customer_name.strip.split(/\s+/)
      first_name = parts.first
      last_name = parts.size > 1 ? parts.last : nil
      if first_name.present? and last_name.present?
        sql = "LOWER(customer_first_name) LIKE LOWER(?) AND LOWER(customer_last_name) LIKE LOWER(?)"
        values = ["%#{first_name}%", "%#{last_name}%"]
      else
        sql = "LOWER(customer_first_name) LIKE LOWER(?) OR LOWER(customer_last_name) LIKE LOWER(?)"
        values = ["%#{first_name}%", "%#{first_name}%"]
      end
      where(sql, *values)
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

    def filter_by_rescinded(filter)
      case filter.try(:to_sym)
        when :exclude_rescinded
          where(rescinded: false)
        when :only_rescinded
          where(rescinded: true)
        else
          scoped
      end
    end

    def filter_by_expired(filter)
      # anything except :only_expired results in the default of hiding expired
      if filter.present? && filter.to_sym == :only_expired
        where(expired: true)
      else
        where(expired: false)
      end
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
        '((TO_TIMESTAMP(CAST(DATE("appointment_time") as character varying(255)) || \' \' || CAST("requested_pickup_time" as character varying(255)), \'YYYY-MM-DD HH24:MI\') - interval \'? seconds\') BETWEEN ? AND ?)',
        '((TO_TIMESTAMP(CAST(DATE("appointment_time") as character varying(255)) || \' \' || CAST("requested_drop_off_time" as character varying(255)), \'YYYY-MM-DD HH24:MI\') - interval \'? seconds\') BETWEEN ? AND ?)'
      ].join(' OR '), datetime_start.utc_offset, datetime_start, datetime_end, datetime_start.utc_offset, datetime_start, datetime_end)
    end

    def filter_by_updated_at(datetime_start, datetime_end)
      query = TripTicket
      query = query.where('"trip_tickets"."updated_at" > ?', datetime_start) unless datetime_start.nil?
      query = query.where('"trip_tickets"."updated_at" <= ?', datetime_end) unless datetime_end.nil?
      query
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
    
    # The ticket_status filter requires that we evaluate the final status of
    # each ticket, which is often calculated dynamically based on related 
    # objects' statuses. Because it has the potential to have to instantiate
    # lots of objects, it's best to run this filter after all other filters
    # are applied.
    # 
    # This method is (unfortunately) tightly coupled to the #claimant_status
    # and #originator_status methods. If they change, this method may need
    # to be updated as well.
    def filter_by_ticket_status(ticket_statuses, provider)
      ticket_statuses = Array(ticket_statuses).compact.map(&:downcase)
      if ticket_statuses.any?
        # This can be a costly filter to apply if the current scope returns
        # lots of records, so let's make debugging future bottlenecks easy.
        # You're welcome, future self.
        logger.debug "-- Filtering #{scoped.count} records through filter_by_ticket_status"

        where(:id => scoped.all.keep_if{ |ticket|
          ticket_status = ticket.status_for(provider).downcase

          # #originator_status may return "{claimant_name} Approved"
          ticket_status = "approved" if !(ticket_status =~ /\bapproved$/).nil?

          # #originator_status may return "{claim_count} Claim(s) Pending"
          ticket_status = "claim pending" if !(ticket_status =~ /\bclaims? pending$/).nil?

          ticket_statuses.include?(ticket_status)
        }.collect(&:id))
      else
        scoped
      end
    end
    
    def expire_tickets!(alternate_logger = nil)
      # Hackish but necessary to get the output we need to log to the cron log
      # when running the rake task, or to display in the console when calling
      # this method directly
      logger = alternate_logger || self.logger
      
      threshold = Time.zone.now
      logger.info "- TripTicket#expire_tickets! called at #{threshold.to_s(:rfc822)}"

      # Note: This task is heavily reliant on times, so we are going to round
      # all times down to the nearest hour.
      threshold = threshold.change(min: 0)
      logger.info "- Threshold adjusted to #{threshold.to_s(:rfc822)}"
      
      affected_tickets = []

      default_query = TripTicket.unscoped.
        # Exclude already expired or rescinded tickets
        where('"trip_tickets"."expired" = ? AND "trip_tickets"."rescinded" = ?', false, false).
        # Exclude tickets that have an approved claim
        where('NOT EXISTS(SELECT 1 FROM trip_claims WHERE trip_ticket_id = trip_tickets.id AND status = \'approved\')').
        # Exclude tickets that have a trip result (currently only possible if the trip is approved or rescinded)
        where('NOT EXISTS(SELECT 1 FROM trip_results WHERE trip_ticket_id = trip_tickets.id)')
        
      # Part 1 - expire tickets with an explicit expire_at date
      logger.debug "- Expiring tickets across all providers where expire_at <= #{threshold.change(min: 59, sec: 59).to_s(:rfc822)}"

      # A necessary hack. See https://github.com/rails/rails/issues/11894
      ids_to_update = default_query.where('expire_at <= ?', threshold.change(min: 59, sec: 59)).pluck(:id)
      updated = TripTicket.update(ids_to_update, Array.new(ids_to_update.size, {expired: true}))

      logger.debug "-- #{updated.size} tickets expired"
      affected_tickets << updated
      
      # Part 2 - use provider default values to look for other tickets eligible for expiration
      logger.debug "- Preparing to expire tickets for each provider"
      Provider.unscoped.each do |provider|
        logger.debug "-- Evaluating tickets for #{provider.name}"
        logger.debug "--- trip_ticket_expiration_days_before = #{provider.trip_ticket_expiration_days_before || "nil"}"
        logger.debug "--- trip_ticket_expiration_time_of_day = #{provider.trip_ticket_expiration_time_of_day || "nil"}"
        if provider.trip_ticket_expiration_days_before.present? && provider.trip_ticket_expiration_time_of_day.present?
          trip_ticket_expiration_time_of_day_adjusted = Time.zone.parse(provider.trip_ticket_expiration_time_of_day.to_s(:time_utc)).change(min: 0).to_s(:time_utc)
          logger.debug "--- trip_ticket_expiration_time_of_day adjusted to #{trip_ticket_expiration_time_of_day_adjusted}"
          logger.debug "--- Checking to see if threshold time >= trip_ticket_expiration_time_of_day_adjusted"
          # We can safely compare this using >= just in case a previous run failed
          if threshold.to_s(:time_utc) >= trip_ticket_expiration_time_of_day_adjusted
            logger.debug "--- #{threshold.to_s(:time_utc)} >= #{trip_ticket_expiration_time_of_day_adjusted}"
            
            # Calculate number of days ahead
            end_date = threshold.to_date
            logger.debug "--- counting #{provider.trip_ticket_expiration_days_before} weekdays ahead from #{end_date.strftime("%a, %e %b %Y")}"
            counter = 0
            while counter < provider.trip_ticket_expiration_days_before do
              end_date = end_date + 1.day
              counter += 1 unless [0,6].include?(end_date.wday)
              logger.debug "--- added #{end_date.strftime("%a, %e %b %Y")}, now at #{counter} weekdays ahead"
            end
            logger.debug "--- end date = #{end_date.strftime("%a, %e %b %Y")}"
            
            expire_at = end_date.end_of_day
            logger.debug "--- Expiring tickets for #{provider.name} where appointment_time <= #{expire_at.to_s(:rfc822)}"
            
            # A necessary hack. See https://github.com/rails/rails/issues/11894
            ids_to_update = default_query.where('origin_provider_id = ? AND expire_at IS NULL AND appointment_time <= ?', provider.id, expire_at).pluck(:id)
            updated = TripTicket.update(ids_to_update, Array.new(ids_to_update.size, {expired: true}))
            logger.debug "---- #{updated.size} tickets expired"
            
            affected_tickets << updated
          else
            logger.debug "--- #{threshold.to_s(:time_utc)} < #{trip_ticket_expiration_time_of_day_adjusted}, skipping provider"
          end
        else
          logger.debug "--- Expiring tickets for #{provider.name} where requested_pickup_time <= #{threshold.change(min: 59, sec: 59).to_s(:rfc822)}"
          
          # A necessary hack. See https://github.com/rails/rails/issues/11894
          ids_to_update = default_query.where('origin_provider_id = ? AND expire_at IS NULL AND (TO_TIMESTAMP(CAST(DATE(appointment_time) AS character varying(255)) || \' \' || CAST(requested_pickup_time AS character varying(255)), \'YYYY-MM-DD HH24:MI\') - interval \'? seconds\') <= ?', provider.id, threshold.utc_offset, threshold.change(min: 59, sec: 59)).pluck(:id)
          updated = TripTicket.update(ids_to_update, Array.new(ids_to_update.size, {expired: true}))

          logger.debug "---- #{updated.size} tickets expired"
          affected_tickets << updated
        end
      end
      
      return affected_tickets.flatten.sort_by(&:id)
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
