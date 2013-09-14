# Using the Reports::Report class
#
# To create a report, first subclass Reports::Report in a file name ending with _report.rb.
# Create a class method #title that returns the title or a default will be created using the class name.
# If you want a table in your report, define the methods #headers and/or #rows.
# To add a summary section to the report, define the method #summary (summary sections
# look like a form, with a label and value on each row).
# You can use a table or summary section alone, or combine both. Summary appears below the table.
#
# Method #headers:
# Should be an array of arrays containing header row values.
# These will be put into the thead section of the report table.
#
# Method #rows:
# Should be an array of rows, where each data row is an array of values.
# Rows should have the same number of values as the headers. Sparse rows are not supported.
# Section break rows can be inserted by returning a hash instead of an array as follows:
# { 'Section Title' => :title }
# Subtotals and Totals rows can be inserted by returning a hash instead of an array as follows:
# { [ 1, 2, 3, 4 ] => :subtotal }
# { [ 10, 20, 30, 40 ] => :total }
#
# Method #summary:
# Summary should be an array of hashes, e.g.: [{ "Total widgets" => "215", "Total sprockets" => "305" }]
# Each hash will be displayed as a separate section.
# To give a section a title, include a hash entry with value :title, e.g. { 'Section Title' => :title }
# Summary can also be a simple hash to create a summary section with no title or section styling.
#
# Convenience Methods
# The following methods can be used to help in generating output data in the proper format:
#
# #create_table_section(title, new_rows)
# #create_title_row(title)
# #create_data_row(row_values)
# #create_subtotals_row(row_values)
# #create_totals_row(row_values)
# #create_summary_section(title, data_hash)
#
# This #date_condition(field_name, options) method can be used to generate a SQL WHERE condition on the
# specified date or timestamp field. The options hash is assumed to include :date_begin and/or :date_end.
#
# Helpers
# reports/helpers.rb contains helpers that can be used in a view to render reports.
#
# Controller Support
# When this class is included in a controller, the method available_reports is defined which returns an array
# of hashes with the form, { id: "report id", title: "My Report Title", klass: MyReportClass }. This method is
# defined as a helper method so it is available in views. Also defined are the methods report_title and report_class
# which accept a report ID parameter and return the title or class of the report. These are also defined as helpers.

require 'reports/helpers'
require 'reports/registry'

module Reports
  extend ActiveSupport::Concern

  include Reports::Registry

  included do
    helper Reports::Helpers
  end

  module Config
    mattr_accessor :reports_parent_directory
  end

  class Report
    attr_accessor :report_id, :user, :options, :errors

    def initialize(report_id, user, options = {})
      raise ArgumentError, "A valid user is required for generating reports" if user.blank?
      self.report_id = report_id.to_s
      self.user = user
      self.options = options.with_indifferent_access
      self.errors = []
      @report_class = "Reports::#{self.report_id.camelize}".constantize
    end

    def run
      raise RuntimeError, "Invalid report parameters" unless valid?
      @report_instance = @report_class.new(user, options)
    end

    def valid?
      self.errors = []
      if options[:date_begin].present? && options[:date_begin].is_a?(String)
        options[:date_begin] = Time.zone.parse(options[:date_begin]) rescue nil
        errors << "Start date is invalid" if options[:date_begin].nil?
      end
      if options[:date_end].present? && options[:date_end].is_a?(String)
        options[:date_end] = Time.zone.parse(options[:date_end]) rescue nil
        errors << "End date is invalid" if options[:date_end].nil?
      end
      errors.blank?
    end

    def title
      @report_class.respond_to?(:title) ? @report_class.title : report_id.titleize
    end

    def headers
      @report_instance.respond_to?(:headers) ? @report_instance.headers : []
    end

    def rows
      @report_instance.respond_to?(:rows) ? @report_instance.rows : []
    end

    def summary
      @report_instance.respond_to?(:summary) ? @report_instance.summary : []
    end

    protected

    # convenience methods for adding data rows in the proper format

    def create_table_section(title, new_rows)
      create_title_row(title)
      self.rows += new_rows
    end

    def create_title_row(title)
      self.rows ||= []
      self.rows << { title => :title }
    end

    def create_data_row(row_values)
      self.rows ||= []
      self.rows << row_values
    end

    def create_subtotals_row(row_values)
      self.rows ||= []
      self.rows << { row_values => :subtotal }
    end

    def create_totals_row(row_values)
      self.rows ||= []
      self.rows << { row_values => :total }
    end

    # convenience methods for adding summary sections in the proper format

    def create_summary_section(title, data_hash)
      data_hash[title] = :title
      self.summary ||= []
      self.summary << data_hash
    end

    # miscellaneous data munging helpers

    # returns a hash where keys are the result of invoking the specified category method
    # on each list entry and values are the count of list entries for that category
    def summarize_object_counts_by_category(list, *category_method_and_params)
      result = {}
      list.each do |entry|
        category = (entry.send(*category_method_and_params) || "").capitalize
        result[category] ||= 0
        result[category] += 1
      end
      result
    end

    # reports can use this to generate their date range conditions

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
