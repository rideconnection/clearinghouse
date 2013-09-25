require 'test_helper'
require 'reports/report'

class ReportsTest < ActiveSupport::TestCase

  describe "Reports module" do
    setup do
      @old_config = Reports::Config.report_directory
      Reports::Config.report_directory = File.join(Rails.root, 'test', 'support')
      class ReportsTestController < ApplicationController
        include Reports
      end
      @controller = ReportsTestController.new
    end

    teardown do
      Reports::Config.report_directory = @old_config
    end

    it "should automatically include the Reports::Registry module" do
      ReportsTestController.ancestors.must_include Reports::Registry
      @controller.must_respond_to(:report_list)
      @controller.must_respond_to(:report_title)
      @controller.must_respond_to(:report_class)
    end

    it "should automatically include the Reports::Helpers module" do
      ReportsTestController.helpers.must_respond_to(:report_table)
      ReportsTestController.helpers.must_respond_to(:report_header)
      ReportsTestController.helpers.must_respond_to(:report_body)
      ReportsTestController.helpers.must_respond_to(:report_summary)
    end

    describe "Reports::Registry module" do
      it "should create a list of all known reports" do
        @controller.report_list.must_be_kind_of(Array)
        @controller.report_list.must_include({ id: 'test_summary_report', title: 'Test Summary Report', klass: Reports::TestSummaryReport })
        @controller.report_list.must_include({ id: 'test_table_report', title: 'A Custom Report Title', klass: Reports::TestTableReport })
      end

      it "should support looking up a report title by id" do
        @controller.report_title('test_summary_report').must_equal 'Test Summary Report'
      end

      it "should support looking up a report class by id" do
        @controller.report_class('test_summary_report').must_equal Reports::TestSummaryReport
      end

      it "should declare Reports::Registry methods as helpers" do
        ReportsTestController.helpers.must_respond_to(:report_title)
        ReportsTestController.helpers.must_respond_to(:report_class)
        ReportsTestController.helpers.must_respond_to(:report_list)
      end
    end
  end

  describe "Reports::Report" do
    setup do
      @user = FactoryGirl.create(:user)
    end

    describe "#initialize" do
      it "should require a valid user" do
        ->{ Reports::Report.new('test_summary_report', nil) }.must_raise(ArgumentError)
      end

      it "should require a valid report_id" do
        ->{ Reports::Report.new('example_of_invalid_report_id', @user) }.must_raise(NameError)
      end
    end

    describe "#run" do
      it "should raise an exception if report is not valid" do
        report = Reports::Report.new('test_summary_report', @user)
        report.stub :valid?, false do
          ->{ report.run }.must_raise(RuntimeError)
        end
      end

      it "should create a report instance and generate outputs" do
        report = Reports::Report.new('test_summary_report', @user)
        report.summary.length.must_equal 0
        report.run
        report.summary.length.must_be :>=, 1
      end
    end

    describe "#valid?" do
      it "should return false if date options are not valid dates" do
        report = Reports::Report.new('test_summary_report', @user, { date_begin: 'xyz' })
        report.valid?.must_equal false
      end

      it "should create a list of error messages if report is not valid" do
        report = Reports::Report.new('test_summary_report', @user, { date_begin: 'xyz' })
        report.valid?
        report.errors.length.must_be :>=, 1
        report.errors.must_include 'Start date is invalid'
      end
    end

    describe "#title" do
      it "should return a default title based on report_id" do
        report = Reports::Report.new('test_summary_report', @user)
        report.title.must_equal 'Test Summary Report'
      end

      it "should allow report subclass to define a custom title" do
        report = Reports::Report.new('test_table_report', @user)
        report.title.must_equal 'A Custom Report Title'
      end
    end

    describe "#headers" do
      it "should return result of report subclass #headers method" do
        report = Reports::Report.new('test_table_report', @user)
        report.run
        report.headers.must_include ['Header One', 'Header Two']
      end

      it "should return an empty array if subclass has no #headers method" do
        report = Reports::Report.new('test_summary_report', @user)
        report.run
        report.headers.must_equal []
      end
    end

    describe "#rows" do
      it "should return result of report subclass #rows method" do
        report = Reports::Report.new('test_table_report', @user)
        report.run
        report.rows.must_equal [[1, 2]]
      end

      it "should return an empty array if subclass has no #rows method" do
        report = Reports::Report.new('test_summary_report', @user)
        report.run
        report.rows.must_equal []
      end
    end

    describe "#summary" do
      it "should return result of report subclass #summary method" do
        report = Reports::Report.new('test_summary_report', @user)
        report.run
        report.summary.must_include({"Test One"=>1, "Test Two"=>2, "Test Section"=>:title})
      end

      it "should return an empty array if subclass has no #summary method" do
        report = Reports::Report.new('test_table_report', @user)
        report.run
        report.summary.must_equal []
      end
    end

    describe "report subclass instance" do
      setup do
        @report = Reports::TestSummaryReport.new(@user)
      end
      it "should be able to use #create_table_section method to add data rows with a title row" do
        @report.must_respond_to(:create_table_section)
      end

      it "should be able to use #create_title_row method to add a title row" do
        @report.must_respond_to(:create_title_row)
      end

      it "should be able to use #create_data_row method to add a data row" do
        @report.must_respond_to(:create_data_row)
      end

      it "should be able to use #create_subtotals_row method to add a subtotal row" do
        @report.must_respond_to(:create_subtotals_row)
      end

      it "should be able to use #create_totals_row method to add a totals row" do
        @report.must_respond_to(:create_totals_row)
      end

      it "should be able to use #create_summary_section to add a summary section with title" do
        @report.must_respond_to(:create_summary_section)
      end

      it "should be able to use #summarize_object_counts_by_category to generate summary data" do
        @report.must_respond_to(:summarize_object_counts_by_category)
      end

      it "should be able to use #date_condition to generate a SQL WHERE expression on dates" do
        @report.must_respond_to(:date_condition)
      end
    end
  end

end
