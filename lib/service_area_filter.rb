module ServiceAreaFilter
  protected

  # provider_service_area_filter returns the conditions to append to a SQL WHERE clause

  def provider_service_area_filter(provider)
    service_area_filters = provider_applicable_service_area_filters(provider)
    service_area_query(service_area_filters, provider) if service_area_filters.present?
  end

  # add_service_area_joins is required to use the service area filter
  # it adds the pickup and dropoff locations to a trip_tickets query as SQL joins

  def add_service_area_joins(collection)
    collection ||= TripTicket.all
    collection
      .joins('LEFT JOIN "locations" AS "pickup" ON "pickup"."id" = "trip_tickets"."pick_up_location_id"')
      .joins('LEFT JOIN "locations" AS "dropoff" ON "dropoff"."id" = "trip_tickets"."drop_off_location_id"')
  end

  def provider_applicable_service_area_filters(provider)
    service_area_filters = [ :pickup, :dropoff ]
    provider.services.each do |service|
      service_area_filters = service_area_filters - service_area_unfiltered_location_types(service)
    end
    service_area_filters
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

  def service_area_query(service_area_filters, provider)
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
end
