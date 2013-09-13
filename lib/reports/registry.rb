module Reports
  module Registry
    extend ActiveSupport::Concern

    mattr_accessor :report_list

    included do
      REPORTS_PARENT_DIR = File.join(Rails.root, 'lib')
      Dir[File.join(REPORTS_PARENT_DIR, 'reports', '**', '*_report.rb')].each do |file|
        require File.join('reports', File.basename(file))
      end
      Reports::Registry.report_list ||= []
      Reports::Report.descendants.each do |report_class|
        report_id = report_class.name.rpartition('::').last.underscore
        report_title = report_class.title if report_class.respond_to?(:title)
        report_title ||= report_id.titleize
        Reports::Registry.report_list << { id: report_id, title: report_title, klass: report_class }
      end

      helper_method :report_title, :report_class, :available_reports
    end

    def report_title(report_id)
      index = Reports::Registry.report_list.index{|report| report[:id] == report_id }
      Reports::Registry.report_list[index][:title] if index
    end

    def report_class(report_id)
      index = Reports::Registry.report_list.index{|report| report[:id] == report_id }
      Reports::Registry.report_list[index][:klass] if index
    end

    def available_reports
      Reports::Registry.report_list
    end
  end
end
