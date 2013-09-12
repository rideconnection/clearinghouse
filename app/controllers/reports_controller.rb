require 'reports/report'

class ReportsController < ApplicationController
  include Reports

  AVAILABLE_REPORTS = {
    "Provider Summary" => "provider_summary"
  }

  helper_method :available_reports

  def index
  end

  def show
    @report = Report.new(params[:id], current_user)
  end

  protected

  def available_reports
    AVAILABLE_REPORTS
  end

end
