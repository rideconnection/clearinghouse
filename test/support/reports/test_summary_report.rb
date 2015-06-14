require 'reports/report'

module Reports
  class TestSummaryReport < Report
    attr_accessor :summary, :rows

    def initialize(user, options = {})
      create_summary_section("Test Section", { "Test One" => 1, "Test Two" => 2 })
    end
  end
end
