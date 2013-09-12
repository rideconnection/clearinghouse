require 'reports/helpers'

module Reports
  extend ActiveSupport::Concern

  included do
    helper Reports::Helpers
  end

  class Report
    def initialize(report_class, user, options = {})
      raise "A valid user is required for generating reports" if user.blank?
      options = options.with_indifferent_access
      # this works because require isn't scoped
      require File.join("reports", "#{report_class}.rb")
      @report_class = "Reports::#{report_class.camelize}".constantize
      @report_instance = @report_class.new(user, options)
    end

    # TODO might be helpful if report headers and rows can be array of hashes so values can be sparse and in any order

    # if a report has header rows, it should define method #headers
    # #headers should return an array of arrays containing header row values
    def headers
      @report_instance.try(:headers) || []
    end

    # if a report has rows, it should define method #rows
    # #rows should return an array of rows, where each data row is an array
    # section breaks can be inserted by returning a hash for a row as follows:
    # { 'Section Title' => :title }
    # subtotals and totals can be inserted by returning a hash in the array as follows:
    # { [ 1, 2, 3, 4 ] => :subtotal }
    # { [ 10, 20, 30, 40 ] => :total }
    def rows
      @report_instance.try(:rows) || []
    end

    # a summary section is not displayed as a table, but is displayed like a form with labels and values in each row
    # reports should return summary data as a hash: { "Total widgets" => "215", "Total sprockets" => "305"  }
    # if report returns an array of hashes, each hash will be displayed as a section
    # if a hash entry has value :title, it is treated as a section title
    def summary
      @report_instance.try(:summary)
    end

    protected

    # convenience methods for adding data rows in the proper format

    def create_table_section(title, new_rows)
      create_title_row(title)
      rows += new_rows
    end

    def create_title_row(title)
      rows << { title => :title }
    end

    def create_data_row(row_values)
      rows << row_values
    end

    def create_subtotals_row(row_values)
      rows << { row_values => :subtotal }
    end

    def create_totals_row(row_values)
      rows << { row_values => :total }
    end

    # convenience methods for adding summary sections in the proper format

    def create_summary_section(title, data_hash)
      data_hash[title] = :title
      summary << data_hash
    end

    # reports can use this to generate their date range conditions
    # TODO reject invalid date strings so they don't get to the database
    def date_condition(field_name, options)
      condition = ""
      values = []
      if options[:date_begin].present?
        condition << "(#{field_name} >= ?)"
        values << options[:date_begin]
      end
      if options[:date_end].present?
        condition << " AND " if condition.length > 0
        condition << "(#{field_name} < ?)"
        values << options[:date_end]
      end
      condition.present? ? ["(#{condition})", *values] : nil
    end

  end
end
