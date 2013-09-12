require 'reports/report'

module Reports
  module Helpers

    def report_summary(report)
      content_tag(:table, :style => "margin-top:20px") do
        report.summary.collect do |k, v|
          content_tag(:tr) do
            content_tag(:td, :style => "font-weight:bold;padding-bottom:10px;padding-right:10px") { k.to_s } +
            content_tag(:td, :style => "padding-bottom:10px") { v.to_s }
          end
        end.join().html_safe
      end.html_safe
    end

  end
end
