require 'reports/report'

class ReportsController < ApplicationController
  include Reports

  AVAILABLE_REPORTS = {
    "Provider Summary" => "provider_summary"
  }

  helper_method :available_reports, :report_name

  def index
  end

  def show
    options = {}
    options[:date_begin] = params[:date_begin]
    options[:date_end] = params[:date_end]
    @report = Report.new(params[:id], current_user, options)
  end

  protected

  def available_reports
    AVAILABLE_REPORTS
  end

  def report_name
    available_reports.key(params[:id]) + ' Report'
  end

end
