require 'reports/report'

class ReportsController < ApplicationController
  include Reports

  def index
  end

  def show
    options = {}
    options[:date_begin] = params[:date_begin]
    options[:date_end] = params[:date_end]
    @report = Report.new(params[:id], current_user, options)
  end
end
