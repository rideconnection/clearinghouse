require 'active_support/concern'

module OperatingHoursFilter
  extend ActiveSupport::Concern

  protected

  def service_operating_hours_filter(service)
    "EXISTS (" +
      "SELECT 1 FROM operating_hours WHERE (" +
        "(operating_hours.service_id = #{service.id}) " +
        "AND " +
        "(operating_hours.open_time IS NOT NULL) " +
        "AND " +
        "(operating_hours.close_time IS NOT NULL) " +
        "AND " +
        "(EXTRACT(DOW FROM trip_tickets.appointment_time) = operating_hours.day_of_week) " +
        "AND (" +
          "(" +
            "(operating_hours.open_time = '00:00') " +
            "AND " +
            "(operating_hours.close_time = '00:00') " +
          ") OR (" +
            "(operating_hours.open_time != operating_hours.close_time) " +
            "AND " +
            "(trip_tickets.requested_pickup_time BETWEEN operating_hours.open_time AND operating_hours.close_time) " +
            "AND " +
            "(trip_tickets.requested_drop_off_time BETWEEN operating_hours.open_time AND operating_hours.close_time)" +
          ")" +
        ")" +
      ")" +
    ")"
  end
end
