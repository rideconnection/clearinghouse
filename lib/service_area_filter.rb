require 'active_support/concern'

module ServiceAreaFilter
  extend ActiveSupport::Concern

  protected

  def service_area_filter(service)
    pickup_query = '(("pickup"."position" IS NULL) OR EXISTS (' +
      'SELECT 1 FROM "services" ' +
        'WHERE (("services"."id" = ' + service.id.to_s + ') ' +
          'AND ST_Contains("services"."service_area", "pickup"."position"))))'

    dropoff_query = '(("dropoff"."position" IS NULL) OR EXISTS (' +
      'SELECT 1 FROM "services" ' +
        'WHERE (("services"."id" = ' + service.id.to_s + ') ' +
          'AND ST_Contains("services"."service_area", "dropoff"."position"))))'

    case service.service_area_type.to_s
      when 'pickup'
        pickup_query
      when 'dropoff'
        dropoff_query
      when 'both'
        "(#{pickup_query} AND #{dropoff_query})"
      else
        nil
    end
  end

  # add_service_area_joins is required to use the service area filter
  # it adds the pickup and dropoff locations to a trip_tickets query as SQL joins

  def add_service_area_joins(collection)
    collection ||= TripTicket.all
    collection
      .joins('LEFT JOIN "locations" AS "pickup" ON "pickup"."id" = "trip_tickets"."pick_up_location_id"')
      .joins('LEFT JOIN "locations" AS "dropoff" ON "dropoff"."id" = "trip_tickets"."drop_off_location_id"')
  end
end
