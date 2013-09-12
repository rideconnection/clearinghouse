require 'reports/report'

module Reports
  module Helpers

    def report_table(report, &block)
      content_tag(:table) do
        capture(report, &block)
      end.html_safe
    end

    def report_header(report)
      content_tag(:thead) do
        report.headers.collect do |row|
          content_tag(:tr) do
            row.collect do |column|
              content_tag(:th) { column.to_s }
            end.join().html_safe
          end
        end.join().html_safe
      end
    end

    def report_body(report)
      content_tag(:tbody) do
        report.rows.collect do |row|
          if row.is_a?(Array)
            content_tag(:tr) do
              row.collect do |column|
                content_tag(:td) { column.to_s }
              end.join().html_safe
            end
          elsif row.is_a?(Hash)
          end
        end.join().html_safe
      end
    end

    def report_summary(report)
      content_tag(:table) do
        report.summary.collect do |k, v|
          content_tag(:tr) do
            content_tag(:td) { k.to_s } + content_tag(:td) { v.to_s }
          end
        end.join().html_safe
      end
    end

  end
end
