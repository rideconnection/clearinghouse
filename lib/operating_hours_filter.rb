require 'active_support/concern'

module OperatingHoursFilter
  extend ActiveSupport::Concern

  protected

  # handles special cases:
  #
  # 24-hr service where times are defined as midnight to midnight
  # when close time is after midnight, making start time greater than close time (e.g. 05:00 start > 02:00 close)
  #
  # the day_of_week logic is complicated, but necessary to get the day of the week in local time (17:00 Pacific is the next day GMT)

  def service_operating_hours_filter(service)
    "EXISTS (" +
      "SELECT 1 FROM operating_hours WHERE (" +
        "(operating_hours.service_id = #{service.id}) " +
        "AND " +
        "(operating_hours.open_time IS NOT NULL) " +
        "AND " +
        "(operating_hours.close_time IS NOT NULL) " +
        "AND " +
        "(EXTRACT(DOW FROM to_timestamp(trip_tickets.appointment_time::varchar, 'YYYY/MM/DD HH24:MI:SS') AT TIME ZONE '#{Time.zone.tzinfo.name}') = operating_hours.day_of_week) " +
        "AND (" +
          "(" +
            "(operating_hours.open_time = '00:00') AND (operating_hours.close_time = '00:00')" +
          ") OR (" +
            "(operating_hours.open_time != operating_hours.close_time) " +
            "AND " +
            "(trip_tickets.requested_pickup_time BETWEEN operating_hours.open_time AND operating_hours.close_time) " +
            "AND " +
            "(trip_tickets.requested_drop_off_time BETWEEN operating_hours.open_time AND operating_hours.close_time)" +
          ") OR (" +
            "(operating_hours.open_time > operating_hours.close_time) " +
            "AND " +
            "((trip_tickets.requested_pickup_time >= operating_hours.open_time) OR (trip_tickets.requested_pickup_time <= operating_hours.close_time)) " +
            "AND " +
            "((trip_tickets.requested_drop_off_time >= operating_hours.open_time) OR (trip_tickets.requested_drop_off_time <= operating_hours.close_time))" +
          ")" +
        ")" +
      ")" +
    ")"
  end
end
