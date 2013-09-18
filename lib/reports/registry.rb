module Reports
  module Registry
    extend ActiveSupport::Concern

    included do
      cattr_accessor :report_list
      helper_method :report_title, :report_class, :report_list

      if report_list.nil?
        report_dir = Reports::Config.report_directory || File.dirname(__FILE__)
        Rails.logger.debug "Reports::Registry loading reports from: #{report_dir}"
        Dir[File.join(report_dir, '**', '*_report.rb')].each do |file|
          require file
        end
        self.report_list ||= []
        Reports::Report.descendants.each do |report_class|
          report_id = report_class.name.rpartition('::').last.underscore
          report_title = report_class.title if report_class.respond_to?(:title)
          report_title ||= report_id.titleize
          self.report_list << { id: report_id, title: report_title, klass: report_class }
        end
      end
    end

    def report_title(report_id)
      index = report_list.index{|report| report[:id] == report_id }
      report_list[index][:title] if index
    end

    def report_class(report_id)
      index = report_list.index{|report| report[:id] == report_id }
      report_list[index][:klass] if index
    end
  end
end
