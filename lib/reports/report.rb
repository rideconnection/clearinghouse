require 'reports/helpers'

module Reports
  extend ActiveSupport::Concern

  included do
    helper Reports::Helpers
  end

  class Report
    def initialize(report_class, user)
      raise "A valid user is required for generating reports" if user.blank?
      # this works because require isn't scoped
      require File.join("reports", "#{report_class}.rb")
      @report_class = "Reports::#{report_class.camelize}".constantize
      @report_instance = @report_class.new(user)
    end

    # if a report has a header row, it should return an array of arrays or array of hashes
    # if array of arrays each value is used as a column header in order
    # if array of hashes, each value should be something like: { 'Field Description' => 'field_name' }
    def headers
      @report_instance.try(:headers) || []
    end

    # if a report has rows, it should return an array of arrays or array of hashes
    # if array of arrays each value will be used as a column value in order
    # if array of hashes, each value should be something like: { 'field_name' => 'field value' }
    # subtotals and totals can be represented as follows:
    # { 'subtotal' => { 'field_name' => 'field subtotal value' }}
    # { 'total' => { 'field_name' => 'field total value' }}
    def rows
      @report_instance.try(:rows) || []
    end

    # a summary section is not displayed as a table, but is displayed like a form with labels and values in each row
    # reports should return summary data as a hash: { "A description" => "a value", "Another thing" => "thing value"  }
    def summary
      @report_instance.try(:summary)
    end
  end
end
