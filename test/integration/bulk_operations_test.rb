require 'test_helper'

class BulkOperationsTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @password = "Password 1"

    @user = FactoryGirl.create(:user,
      :password => @password,
      :password_confirmation => @password,
      :provider => @provider)
    @user.role = Role.find_or_create_by_name!("provider_admin")
    @user.save!

    @user2 = FactoryGirl.create(:user,
      :password => @password,
      :password_confirmation => @password,
      :provider => @provider)
    @user2.role = Role.find_or_create_by_name!("scheduler")
    @user2.save!

    login_as @user, :scope => :user
    visit '/'
  end

  teardown do
  end

  let(:bulk_operation1) { FactoryGirl.create(:bulk_operation, user_id: @user.id, is_upload: true, row_count: 5, file_name: 'myfile.csv', error_count: 0, data: 'dummy data') }
  let(:bulk_operation2) { FactoryGirl.create(:bulk_operation, user_id: @user.id, row_count: 15, last_exported_timestamp: 1.days.ago, file_name: BulkOperation.make_file_name, error_count: 0) }
  let(:bulk_operation3) { FactoryGirl.create(:bulk_operation, user_id: @user.id, row_count: 5, last_exported_timestamp: 1.hours.ago, file_name: BulkOperation.make_file_name, error_count: 0) }

  def make_bulk_operations(n = 1)
    n.times { FactoryGirl.create(:bulk_operation, user_id: @user.id, row_count: 3, last_exported_timestamp: 1.hours.ago, file_name: BulkOperation.make_file_name, error_count: 0) }
  end

  describe "main navigation" do
    it "should contain a bulk operations entry" do
      assert_selector("#nav a[href='#{ bulk_operations_path }']")
    end
  end

  describe "index view" do
    it "should display a list of bulk operations" do
      click_link "Bulk Operations"
      assert page.has_table?("bulk_operations_list")
    end

    it "should have links to download and upload trip tickets" do
      click_link "Bulk Operations"
      assert page.has_link?("Download Trip Tickets")
      assert page.has_link?("Upload Trip Tickets")
    end

    it "should contain all bulk operations created by the user" do
      bulk_operation1
      bulk_operation2
      bulk_operation3
      click_link "Bulk Operations"
      assert find("#bulk_operations_list thead tr").has_content?("Time Type Status File Name Rows Errors")
      page.all("#bulk_operations_list tbody tr").count.must_equal 3
    end

    it "should only show user their own bulk operations" do
      bulk_operation1
      FactoryGirl.create(:bulk_operation, row_count: 1313, last_exported_timestamp: 1.hours.ago, file_name: BulkOperation.make_file_name, error_count: 0)
      click_link "Bulk Operations"
      page.all("#bulk_operations_list tbody tr").count.must_equal 1
      assert page.find("#bulk_operations_list tbody").has_no_content?('1313')
    end

    it "should paginate the bulk operations list" do
      make_bulk_operations(6)
      click_link "Bulk Operations"
      page.all("#bulk_operations_list tbody tr").count.must_equal 5
      assert page.has_link?('2')
      assert page.has_link?('Next')
      assert page.has_link?('Last')
    end
  end

  describe "download trip tickets" do
    setup do
      @trip_ticket1 = FactoryGirl.create(:trip_ticket, originator: @user.provider, updated_at: 2.days.ago)
      @trip_ticket2 = FactoryGirl.create(:trip_ticket, originator: @user.provider, updated_at: 2.hours.ago)
      @trip_ticket3 = FactoryGirl.create(:trip_ticket, originator: @user.provider, updated_at: 1.minutes.ago)
      click_link "Bulk Operations"
      click_link "Download Trip Tickets"
    end

    it "should initially export all trip tickets" do
      assert page.has_content?("Downloading 3 trip tickets that have been updated since your last download")
    end

    it "should only export only trip tickets updated or created since last download" do
      bulk_operation2
      visit current_path
      assert page.has_content?("Downloading 2 trip tickets that have been updated since your last download")
      bulk_operation3
      visit current_path
      assert page.has_content?("Downloading 1 trip tickets that have been updated since your last download")
    end

    it "should store the timestamp of each user's last download separately" do
      bulk_operation2
      bulk_operation3
      logout :user
      login_as @user2, :scope => :user
      visit '/'
      click_link "Bulk Operations"
      click_link "Download Trip Tickets"
      assert page.has_content?("Downloading 3 trip tickets that have been updated since your last download")
    end

    describe "with delayed_job configured" do
      setup do
        @old_settings = Clearinghouse::Application.config.bulk_operation_options
        Clearinghouse::Application.config.bulk_operation_options = { use_delayed_job: true }
        # stub delayed_job #delay method and count invocations
        class BulkOperationsController
          @@invocation_count = 0
          alias :orig_delay :delay
          self.class.send(:define_method, :delay) do
            @@invocation_count += 1
            self
          end
          def self.invocation_count
            @@invocation_count
          end
        end
      end

      teardown do
        Clearinghouse::Application.config.bulk_operation_options = @old_settings
        class BulkOperationsController
          class << self
            remove_method :invocation_count
          end
          alias :delay :orig_delay
          self.class.send(:remove_method, :delay)
        end
      end

      it "should queue downloads with delayed_jobs" do
        assert_difference 'BulkOperationsController.invocation_count', 1 do
          click_button "Confirm Download"
        end
      end
    end

    it "should redirect to the new bulk operation after a download is started" do
      click_button "Confirm Download"
      assert current_path == "#{bulk_operation_path(BulkOperation.maximum(:id))}"
    end

    describe "bulk operation page" do
      setup do
        click_button "Confirm Download"
        @bulk_operation = BulkOperation.find(BulkOperation.maximum(:id))
      end

      it "should update bulk operation status when bulk operation is complete" do
        assert page.has_content?("Type Download")
        assert page.has_content?("Time #{@bulk_operation.created_at.strftime("%Y-%m-%d %H:%M:%S")}")
        assert page.has_content?("Status Completed")
        assert page.has_content?("Row Count 3")
        assert page.has_content?("Most Recent Trip Ticket Update Time #{@trip_ticket3.updated_at.strftime("%Y-%m-%d %H:%M:%S")}")
      end

      it "should initiate download when download operation is complete" do
        skip "JavaScript testing required"
      end

      it "should allow user to re-download a previously exported file" do
        click_button "Re-download"
        page.response_headers['Content-Type'].must_equal "text/csv"
      end
    end
  end

  describe "upload trip tickets" do
    setup do
      click_link "Bulk Operations"
      click_link "Upload Trip Tickets"
    end

    it "should require a file selection" do
      click_button "Upload"
      assert page.has_content?("File name can't be blank")
    end

    it "should redirect to the new bulk operation after an upload is started" do
      attach_file "bulk_operation_uploaded_file", "#{File.join(Rails.root, 'test', 'fixtures', 'trip_ticket_import_test.csv')}"
      click_button "Upload"
      assert current_path == "#{bulk_operation_path(BulkOperation.maximum(:id))}"
    end

    it "should create new trip tickets after upload operation is complete" do
      attach_file "bulk_operation_uploaded_file", "#{File.join(Rails.root, 'test', 'fixtures', 'trip_ticket_import_test.csv')}"
      assert_difference 'TripTicket.count', 1 do
        click_button "Upload"
      end
    end

    describe "bulk operation page" do
      setup do
        attach_file "bulk_operation_uploaded_file", "#{File.join(Rails.root, 'test', 'fixtures', 'trip_ticket_import_test.csv')}"
        click_button "Upload"
        @bulk_operation = BulkOperation.find(BulkOperation.maximum(:id))
      end

      it "should update bulk operation status when bulk operation is complete" do
        assert page.has_content?("Type Upload")
        assert page.has_content?("Time #{@bulk_operation.created_at.strftime("%Y-%m-%d %H:%M:%S")}")
        assert page.has_content?("Status Completed")
        assert page.has_content?("Row Count 1")
        assert page.has_content?("Error Count 0")
      end
    end
  end
end
