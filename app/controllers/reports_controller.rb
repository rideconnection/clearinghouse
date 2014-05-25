require 'reports/report'

class ReportsController < ApplicationController
  include Reports

  def index
  end

  def show
    params[:date_begin] ||= 1.week.ago.strftime("%Y-%m-%d %I:%M %P")
    options = {}
    options[:date_begin] = params[:date_begin]
    options[:date_end] = params[:date_end]
    @report = Report.new(params[:id], current_user, options)

    if @report.valid?
      @report.run
    else
      flash.now[:alert] = "Invalid report inputs: " + @report.errors.join(", ")
      render
    end
  end
end
