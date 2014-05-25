require 'test_helper'
require 'reports/report'

class ProviderNewTripReportTest < ActiveSupport::TestCase
  setup do
    class TestController < ActionController::Base
      include Reports
    end

    user = FactoryGirl.create(:user)
    provider = user.provider

    claimable_trip = Timecop.freeze(Date.today - 1) { FactoryGirl.create(:trip_ticket, originator: provider) }
    Timecop.freeze(Date.today - 2) { FactoryGirl.create(:trip_ticket, originator: provider, rescinded: true) }
    Timecop.freeze(Date.today - 20) { FactoryGirl.create(:trip_ticket, originator: provider) }

    FactoryGirl.create(:trip_claim, :trip_ticket => claimable_trip, :status => :approved)

    claimed_trip = FactoryGirl.create(:trip_ticket)
    FactoryGirl.create(:trip_claim, :trip_ticket => claimed_trip, claimant: provider, :status => :approved)

    @report = Reports::Report.new('provider_new_trip_report', user, { date_begin: 7.days.ago, date_end: nil })
    @report.run
  end

  it "should include table header data" do
    @report.headers.must_equal [['Submitted', 'Customer and Seats', 'Appointment Time', 'Pickup', 'Drop-off', 'Status']]
  end

  it "should only include trips originated by provider in the specified date range" do
    @report.rows.length.must_equal 2
  end

  it "should order trips by created timestamp" do
    @report.rows[0].last.must_equal 'Rescinded'
    @report.rows[1].last.must_equal 'Awaiting Result'
  end

  it "should include a summary line with the total number of new trips" do
    @report.summary.must_equal({ "Total New Trip Tickets" => 2 })
  end
end
