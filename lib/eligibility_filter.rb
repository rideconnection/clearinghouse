module EligibilityFilter
  protected

  def provider_eligibility_filter(collection, provider)
    collection ||= TripTicket.all
    query_str = ""
    query_params = []
    service_area_filters = [ :pickup, :dropoff ]

    provider.services.each do |service|
      # Service area filtering
      service_area_filters = service_area_filters - service_area_unfiltered_location_types(service)

      # Eligibility requirements filtering
      service.eligibility_requirements.each do |requirement|
        new_sql, new_params = eligibility_requirement_filter(requirement)
        if new_sql.present?
          query_str << " OR " if query_str.present?
          query_str << new_sql
          query_params = query_params + new_params
        end
      end
    end

    if service_area_filters.present?
      service_area_query = service_area_filter(service_area_filters, provider)
      collection = add_service_area_filter(collection, service_area_query)
    end

    collection = collection.where(query_str, *query_params) if query_str.present?
    collection
  end

  # given a service's setting for filtering trip tickets by service area, this returns
  # an array of location types that will not be filtered at all by this service.
  # E.g. if a service specifies that only pickup must be within the service area, then it accepts ALL drop-off
  # locations, so we should not filter by drop-off location at all.
  def service_area_unfiltered_location_types(service)
    case service.service_area_type.to_s
      when 'pickup'
        [ :dropoff ]
      when 'dropoff'
        [ :pickup ]
      when 'both'
        []
      else
        # this service does not filter by location, it accepts trips that are anywhere
        [ :pickup, :dropoff ]
    end
  end

  def service_area_filter(service_area_filters, provider)
    # add this at most once to the complete query
    pickup_query = '(("pickup"."position" IS NULL) OR EXISTS (' +
      'SELECT 1 FROM "services" ' +
        'WHERE (("services"."provider_id" = ' + provider.id.to_s + ') ' +
          'AND ST_Contains("services"."service_area", "pickup"."position"))))'

    # add this at most once to the complete query
    dropoff_query = '(("dropoff"."position" IS NULL) OR EXISTS (' +
      'SELECT 1 FROM "services" ' +
        'WHERE (("services"."provider_id" = ' + provider.id.to_s + ') ' +
          'AND ST_Contains("services"."service_area", "dropoff"."position"))))'

    if service_area_filters.include?(:pickup) && service_area_filters.include?(:dropoff)
      "(#{pickup_query} AND #{dropoff_query})"
    elsif service_area_filters.include?(:pickup)
      pickup_query
    elsif service_area_filters.include?(:dropoff)
      dropoff_query
    else
      nil
    end
  end

  def add_service_area_filter(collection, query_str)
    if query_str.present?
      collection = collection
        .joins('LEFT JOIN "locations" AS "pickup" ON "pickup"."id" = "trip_tickets"."pick_up_location_id"')
        .joins('LEFT JOIN "locations" AS "dropoff" ON "dropoff"."id" = "trip_tickets"."drop_off_location_id"')
        .where(query_str)
    end
    collection
  end

  def eligibility_requirement_filter(requirement)
    join_str = " #{requirement.boolean_type.upcase} "
    query_str = ""
    query_params = []
    requirement.eligibility_rules.each do |rule|
      new_sql, new_params = eligibility_rule_filter(rule)
      if new_sql.present?
        query_str << join_str if query_str.present?
        query_str << new_sql
        query_params = query_params + new_params
      end
    end
    return "(#{query_str})", query_params
  end

  def eligibility_rule_filter(rule)
    query_str = ""
    query_params = []
    case rule.trip_field
      when 'customer_dob'
        # convert specified age to dates in the past and compare to date of birth field
        age_target = rule.comparison_value.to_i
        less_than_dob = age_target.years.ago.midnight + 1.day
        greater_than_dob = (age_target + 1).years.ago.midnight + 1.day
        case rule.comparison_type
          when 'equal'
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob < ?) AND (trip_tickets.customer_dob >= ?)"
            query_params = [ less_than_dob, greater_than_dob ]
          when 'not_equal'
            query_str = "(trip_tickets.customer_dob IS NULL) OR (trip_tickets.customer_dob >= ?) OR (trip_tickets.customer_dob < ?)"
            query_params = [ less_than_dob, greater_than_dob ]
          when 'greater_than'
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob < ?)"
            query_params = [ greater_than_dob ]
          when 'less_than'
            query_str = "(trip_tickets.customer_dob IS NOT NULL) AND (trip_tickets.customer_dob >= ?)"
            query_params = [ less_than_dob ]
        end
      when *TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.stringify_keys.keys
        # array columns
        case rule.comparison_type
          when 'contain'
            query_str = "lower(?::text) LIKE ?"
            query_params = [ rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = "(? IS NULL) OR (lower(?::text) NOT LIKE ?)"
            query_params = [ rule.trip_field, rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = "? = ANY (lower(?::text)::text[])"
            query_params = [ rule.comparison_value.downcase, rule.trip_field ]
          when 'not_equal'
            query_str = "(? IS NULL) OR (? != ALL (lower(?::text)::text[]))"
            query_params = [ rule.trip_field, rule.comparison_value.downcase, rule.trip_field ]
        end
      else
        # normal columns
        case rule.comparison_type
          when 'contain'
            query_str = "lower(?) LIKE ?"
            query_params = [ rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'not_contain'
            query_str = "(? IS NULL) OR (lower(?) NOT LIKE ?)"
            query_params = [ rule.trip_field, rule.trip_field, "%#{rule.comparison_value.downcase}%" ]
          when 'equal'
            query_str = "lower(?) = ?"
            query_params = [ rule.trip_field, rule.comparison_value.downcase ]
          when 'not_equal'
            query_str = "(? IS NULL) OR (lower(?) = ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
          when 'greater_than'
            query_str = "(? IS NOT NULL) AND (? > ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
          when 'less_than'
            query_str = "(? IS NOT NULL) AND (? < ?)"
            query_params = [ rule.trip_field, rule.trip_field, rule.comparison_value.downcase ]
        end
    end
    return "(#{query_str})", query_params
  end
end
