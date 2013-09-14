require 'reports/report'

module Reports
  class ProviderSummaryReport < Report
    attr_accessor :summary

    #def self.title
    #  "Custom Title Here, default would be Provider Summary Report based on class name"
    #end

    def initialize(user, options = {})
      created_trips = user.provider.trip_tickets.where(date_condition('trip_tickets.created_at', options))
      updated_trips = user.provider.trip_tickets.where(date_condition('trip_tickets.updated_at', options))
      created_offers = user.provider.trip_tickets.joins(:trip_claims).where(date_condition('trip_claims.created_at', options))
      updated_offers = user.provider.trip_tickets.joins(:trip_claims).where(date_condition('trip_claims.updated_at', options))
      created_requests = user.provider.trip_claims.where(date_condition('trip_claims.created_at', options))
      updated_requests = user.provider.trip_claims.where(date_condition('trip_claims.updated_at', options))

      section_data = { "Total new trips" => created_trips.count }
      create_summary_section("New Trip Tickets", section_data)

      section_data = { "Total updated trips" => updated_trips.count }
      section_data.merge(summarize_object_counts_by_category(updated_trips, :status_for, user))
      create_summary_section("Updated Trip Tickets", section_data)

      section_data = { "Total new offers" => created_offers.count }
      create_summary_section("New Claim Offers Received", section_data)

      section_data = { "Total updated offers" => updated_offers.count }
      section_data.merge(summarize_object_counts_by_category(updated_offers, :status))
      create_summary_section("Updated Claim Offers Received", section_data)

      section_data = { "Total new requests" => created_requests.count }
      create_summary_section("New Claim Requests Submitted", section_data)

      section_data = { "Total updated requests" => updated_requests.count }
      section_data.merge(summarize_object_counts_by_category(updated_requests, :status))
      create_summary_section("Updated Claim Requests Submitted", section_data)
    end
  end
end