require 'reports/report'

module Reports
  class ProviderSummary < Report
    def initialize(user)
      @report_user = user
      @summary = {
        "Trip tickets submitted" => @report_user.provider.trip_tickets.count,
        "Claim offers received" => @report_user.provider.trip_tickets.joins(:trip_claims).count,
        "Claim requests made" => @report_user.provider.trip_claims.count
      }
    end

    def summary
      @summary
    end
  end
end