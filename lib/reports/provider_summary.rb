require 'reports/report'

module Reports
  class ProviderSummary < Report
    def initialize(user, options = {})
      @report_user = user

      trips = @report_user.provider.trip_tickets.where(date_condition('trip_tickets.created_at', options)).count
      offers = @report_user.provider.trip_tickets.joins(:trip_claims).where(date_condition('trip_claims.created_at', options)).count
      requests = @report_user.provider.trip_claims.where(date_condition('trip_claims.created_at', options)).count

      @summary = [
        { "Overall" => :title,
          "Trip tickets submitted" => trips,
          "Claim offers received" => offers,
          "Claim requests made" => requests },
        {  "Blah Blah" => :title,
          "Trip tickets submitted" => trips / 2,
          "Claim offers received" => offers / 2,
          "Claim requests made" => requests / 2 }
        ]
    end

    def summary
      @summary
    end
  end
end