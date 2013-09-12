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
          content_tag(:tr) { row.collect {|column| content_tag(:th) { column.to_s }}.join().html_safe }
        end.join().html_safe
      end
    end

    def report_body(report)
      content_tag(:tbody) do
        report.rows.collect do |row|
          if row.is_a?(Hash)
            if row.key(:title)
              content_tag(:tr) { content_tag(:td, colspan: 42) { row.key(:title) }}
            elsif row.key(:subtotal) || row.key(:total)
              type = row.key(:subtotal) ? 'Subtotals' : 'Totals'
              row_vals = row.key(:subtotal) || row.key(:total)
              content_tag(:tr) { content_tag(:td, colspan: 42) { type }} +
              content_tag(:tr) { row_vals.collect { |column| content_tag(:td) { column.to_s }}.join().html_safe }
            end
          else
            content_tag(:tr) { row.collect { |column| content_tag(:td) { column.to_s }}.join().html_safe }
          end
        end.join().html_safe
      end
    end

    def report_summary(report)
      content_tag(:table) do
        if report.summary.is_a?(Array)
          # each array entry is a separate report section
          report.summary.collect do |section|
            title = section.key(:title)
            if title.present?
              section.delete(title)
              content_tag(:tr) { content_tag(:td, colspan: 2) { content_tag(:hr) + content_tag(:h1, title.to_s) }}
            else
              content_tag(:tr) { content_tag(:td, colspan: 2) }
            end +
            section.collect do |k, v|
              content_tag(:tr) { content_tag(:td) { k.to_s } + content_tag(:td) { v.to_s }}
            end.join().html_safe
          end.join().html_safe
        else
          report.summary.collect do |k, v|
            content_tag(:tr) { content_tag(:td) { k.to_s } + content_tag(:td) { v.to_s }}
          end.join().html_safe
        end
      end
    end

  end
end
