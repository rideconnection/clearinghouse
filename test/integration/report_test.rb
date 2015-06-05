require 'test_helper'

shared_examples 'should support date range filtering' do |date_begin, test_if_filtered|
  test "should include inputs for begin and end date" do
    assert page.has_field?('date_begin')
    assert page.has_field?('date_end')
  end

  test "should filter results by date range" do
    fill_in('date_begin', with: date_begin.in_time_zone(@user.time_zone).strftime('%Y-%m-%d %I:%M %P'))
    click_button 'Filter Report'
    assert test_if_filtered.call(page)
  end
end


class ReportTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    @user = FactoryGirl.create(:user)
    @user.role = Role.find_or_create_by_name!("provider_admin")
    @user.save!
    @provider = @user.provider

    Time.zone = @user.time_zone

    login_as @user, :scope => :user
    visit '/'
    click_link 'Reports'
  end

  before do
    Timecop.freeze
  end

  after do
    Timecop.return
  end

  test 'user can view a list of available reports' do
    assert page.has_link?('Provider Summary Report')
    assert page.has_link?('Provider New Trip Tickets Report')
  end

  context 'Provider Summary Report' do
    setup do
      claimable_trip = FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 1.days.ago)
      FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 2.days.ago, rescinded: true)
      FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 20.days.ago)

      FactoryGirl.create(:trip_claim, :trip_ticket => claimable_trip, :status => :approved)

      claimed_trip = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :trip_ticket => claimed_trip, claimant: @provider, :status => :approved)

      click_link 'Provider Summary Report'
    end

    include_examples('should support date range filtering',
                     1.days.ago,
                     ->(page){ page.find('tr', text: 'Total new trips').has_content?('1') })

    test 'should contain the report title' do
      within('#content header') { assert page.has_content?('Provider Summary Report') }
    end

    test 'should contain a summary section' do
      assert page.has_css?('table.report-summary')
      page.all('table.report-summary tr').length.must_be :>=, 1
    end

    test 'should contain a section for new trip tickets by status' do
      within('table.report-summary') do
        assert page.has_content?('New Trip Tickets')
        assert find('tr', text: 'Total new trips').has_content?('2')
        assert find('tr', text: 'Awaiting result').has_content?('1')
        assert find('tr', text: 'Rescinded').has_content?('1')
      end
    end

    test 'should contain a section for new claim offers by status' do
      within('table.report-summary') do
        assert page.has_content?('New Claim Offers Received')
        assert find('tr', text: 'Total new offers').has_content?('1')
        assert find('tr', text: 'Resolved').has_content?('1')
      end
    end

    test 'should contain a section for new claim requests by status' do
      within('table.report-summary') do
        assert page.has_content?('New Claim Requests Submitted')
        assert find('tr', text: 'Total new requests').has_content?('1')
        assert find('tr', text: 'Approved').has_content?('1')
      end
    end
  end

  context 'Provider New Trip Report' do
    setup do
      @trip1 = FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 1.days.ago)
      @trip2 = FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 2.days.ago, rescinded: true)
      FactoryGirl.create(:trip_ticket, originator: @provider, created_at: 20.days.ago)

      FactoryGirl.create(:trip_claim, :trip_ticket => @trip1, :status => :approved)

      claimed_trip = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :trip_ticket => claimed_trip, claimant: @provider, :status => :approved)

      click_link 'Provider New Trip Tickets Report'
    end

    include_examples('should support date range filtering',
                     1.days.ago,
                     ->(page){ page.all('table.report-table tbody tr').length.must_equal(1) })

    test 'should contain the report title' do
      within('#content header') { assert page.has_content?('Provider New Trip Tickets Report') }
    end

    test 'should contain a table section' do
      assert page.has_css?('table.report-table')
      page.all('table.report-table tr').length.must_be :>=, 1
    end

    test 'should have a row of headers' do
      within('table.report-table thead') do
        assert page.has_content?('Submitted')
        assert page.has_content?('Customer and Seats')
        assert page.has_content?('Appointment Time')
        assert page.has_content?('Pickup')
        assert page.has_content?('Drop-off')
        assert page.has_content?('Status')
      end
    end

    test 'should only contain trip tickets originated by user\'s provider within specified date range' do
      all('table.report-table tbody tr').count.must_equal(2)
    end

    test 'should show the created timestamp for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?(@trip1.created_at.strftime('%I:%M %p %b %d'))
        assert page.has_content?(@trip2.created_at.strftime('%I:%M %p %b %d'))
      end
    end

    test 'should show the customer name and seats required for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?("#{@trip1.customer_full_name} #{@trip1.seats_required}")
        assert page.has_content?("#{@trip2.customer_full_name} #{@trip2.seats_required}")
      end
    end

    test 'should show the appointment time for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?(@trip1.appointment_time.strftime '%I:%M %p %b %d')
        assert page.has_content?(@trip2.appointment_time.strftime '%I:%M %p %b %d')
      end
    end

    test 'should show the pickup address for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?(@trip1.pick_up_location.try(:address_and_city, ', '))
        assert page.has_content?(@trip2.pick_up_location.try(:address_and_city, ', '))
      end
    end

    test 'should show the customer drop-off address for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?(@trip1.drop_off_location.try(:address_and_city, ', '))
        assert page.has_content?(@trip2.drop_off_location.try(:address_and_city, ', '))
      end
    end

    test 'should show the trip ticket status for each trip' do
      within('table.report-table tbody') do
        assert page.has_content?(@trip1.status_for(@user))
        assert page.has_content?(@trip2.status_for(@user))
      end
    end

    test 'should contain a summary section' do
      assert page.has_css?('table.report-summary')
      page.all('table.report-summary tr').length.must_be :>=, 1
    end

    test 'should summarize the total numnber of new trips' do
      within('table.report-summary') do
        assert find('tr', text: 'Total New Trip Tickets').has_content?('2')
      end
    end
  end
end
