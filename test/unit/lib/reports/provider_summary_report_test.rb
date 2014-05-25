require 'test_helper'
require 'reports/report'

class ProviderSummaryReportTest < ActiveSupport::TestCase
  setup do
    class TestController < ActionController::Base
      include Reports
    end

    user = FactoryGirl.create(:user)
    provider = user.provider

    claimable_trip = FactoryGirl.create(:trip_ticket, originator: provider, created_at: 1.days.ago)
    FactoryGirl.create(:trip_ticket, originator: provider, created_at: 1.days.ago, rescinded: true)
    FactoryGirl.create(:trip_ticket, originator: provider, created_at: 20.days.ago)

    FactoryGirl.create(:trip_claim, :trip_ticket => claimable_trip, :status => :approved)

    claimed_trip = FactoryGirl.create(:trip_ticket)
    FactoryGirl.create(:trip_claim, :trip_ticket => claimed_trip, claimant: provider, :status => :approved)

    @report = Reports::Report.new('provider_summary_report', user, { date_begin: 7.days.ago, date_end: nil })
    @report.run
  end

  it "should only include trips created in the specified date range" do
    @report.summary[0]['Total new trips'].must_equal 2
  end

  it "should include a section title for trip tickets" do
    @report.summary[0]['New Trip Tickets'].must_equal :title
  end

  it "should include a section title for claim offers received" do
    @report.summary[1]['New Claim Offers Received'].must_equal :title
  end

  it "should include a section title for claim requests submitted" do
    @report.summary[2]['New Claim Requests Submitted'].must_equal :title
  end

  it "should include a summary line with the total number of new trips" do
    @report.summary[0].keys.must_include('Total new trips')
  end

  it "should include a summary line with the total number of new claim offers received" do
    @report.summary[1].keys.must_include('Total new offers')
  end

  it "should include a summary line with the total number of new claim requests submitted" do
    @report.summary[2].keys.must_include('Total new requests')
  end

  it "should include summary lines with the total number of trips by status" do
    @report.summary[0].keys.must_include('Awaiting result')
    @report.summary[0]['Awaiting result'].must_equal 1
    @report.summary[0].keys.must_include('Rescinded')
    @report.summary[0]['Rescinded'].must_equal 1
  end

  it "should include summary lines with the total number of claim offers by status" do
    @report.summary[1].keys.must_include('Resolved')
    @report.summary[1]['Resolved'].must_equal 1
  end

  it "should include summary lines with the total number of claim requests by status" do
    @report.summary[2].keys.must_include('Approved')
    @report.summary[2]['Approved'].must_equal 1
  end
end
