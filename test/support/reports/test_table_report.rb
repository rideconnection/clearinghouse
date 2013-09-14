require 'reports/report'

module Reports
  class TestTableReport < Report
    attr_accessor :header, :rows

    def self.title
      "A Custom Report Title"
    end

    def headers
      [['Header One', 'Header Two']]
    end

    def initialize(user, options = {})
      create_data_row([1, 2])
    end
  end
end
