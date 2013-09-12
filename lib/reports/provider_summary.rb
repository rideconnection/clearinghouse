require 'reports/report'

module Reports
  class ProviderSummary < Report
    def initialize(user, options = {})
      @report_user = user
      @data = []

      created_trips = @report_user.provider.trip_tickets.where(date_condition('trip_tickets.created_at', options))
      updated_trips = @report_user.provider.trip_tickets.where(date_condition('trip_tickets.updated_at', options))
      offers = @report_user.provider.trip_tickets.joins(:trip_claims).where(date_condition('trip_claims.created_at', options))
      requests = @report_user.provider.trip_claims.where(date_condition('trip_claims.created_at', options))

      section_data = {
        "New trips submitted" => created_trips.count
      }
      updated_trips.each do |trip|
        status = trip.simple_originator_status(user.provider)
        section_data[status] ||= 0
        section_data[status] += 1
      end
      create_summary_section("Trip Tickets", section_data)

      section_data = {
        "Claim offers received" => offers.count,
        "Claim requests made" => requests.count
      }
      create_summary_section("Trip Claims", section_data)
    end

    def summary
      @data
    end
  end
end