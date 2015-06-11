require 'test_helper'

class TripTicketsTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @password = "Password 1"

    @user = FactoryGirl.create(:user, 
      :password => @password, 
      :password_confirmation => @password, 
      :provider => @provider)
    @user.role = Role.find_or_create_by!(name: "provider_admin")
    @user.save!

    login_as @user, :scope => :user
    visit '/'
  end

  teardown do
    # For selectively enabling selenium driven tests
    # Capybara.current_driver = nil # reset
  end

  test "provider admins can create new trip tickets" do
    click_link "Tickets"
    click_link "Add New"
    
    fill_in_minimum_required_trip_ticket_fields

    fill_in "Ethnicity", :with => "Not of Hispanic Origin"
    fill_in "Race", :with => "Asian"
    fill_in "Trip Purpose", :with => "Some information"
    
    click_button "Create Trip ticket"
    
    assert page.has_content?("Trip ticket was successfully created")
  end

  test "provider admins can create trip ticket comments" do 
    ticket = FactoryGirl.create(:trip_ticket, 
      :origin_provider_id => @user.provider.id)
    visit trip_ticket_path(ticket)
    click_link "Add Comment"
    fill_in :trip_ticket_comment_body, :with => "a comment!"
    click_button "Create Trip ticket comment"
    assert page.has_content?("Trip ticket comment was successfully created.")
  end 

  describe "TripTicket#status_for(user)" do

    # tests to make sure status shows up in the UI where expected

    it "should be displayed in the trip ticket index" do
      trip = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => 20.days.from_now)
      visit trip_tickets_path
      assert page.find("#standard_ticket_list").has_content?("No Claims")
    end

    ## No longer valid since the unified view has been swapped out for an AJAX dashboard that is rendered at run-time
    # it "should be displayed in the trip ticket unified view" do      
    #   trip = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => 20.days.from_now)
    #   visit trip_tickets_path
    #   assert page.find(".content-frame>.heading:first").has_content?("No Claims")
    # end

    it "should be displayed in the trip ticket show action" do
      trip = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => 20.days.from_now)
      visit trip_ticket_path(trip)
      assert page.has_content?("No Claims")
    end

    # the remainder of the status tests ensure compliance with the trip status grid spreadsheet

    describe "when current user belongs to originator" do
      setup do
        @trip_ticket = FactoryGirl.create(
            :trip_ticket,
            :origin_provider_id => @user.provider.id,
            :appointment_time => 2.days.from_now)
      end

      it "should return New if trip ticket is unsaved" do
        TripTicket.new.status_for(@user).must_equal 'New'
      end

      it "should return Rescinded if trip ticket is rescinded" do
        @trip_ticket.tap {|t| t.rescind! }.status_for(@user).must_equal 'Rescinded'
      end

      it "should return Expired if trip ticket is expired" do
        @trip_ticket.tap {|t| t.expired = true }.status_for(@user).must_equal 'Expired'
      end

      it "should return No Claims if trip ticket has no claims" do
        @trip_ticket.status_for(@user).must_equal 'No Claims'
      end

      it "should return No Claims if trip ticket has only rescinded claims" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :rescinded)
        @trip_ticket.status_for(@user).must_equal 'No Claims'
      end

      it "should return Claims Pending with a count if trip ticket has claims" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
        @trip_ticket.status_for(@user).must_equal '1 Claim Pending'
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
        @trip_ticket.status_for(@user).must_equal '2 Claims Pending'
      end

      it "should not count rescinded claims in Claims Pending" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :rescinded)
        @trip_ticket.status_for(@user).must_equal '1 Claim Pending'
      end

      it "should return Approved with the name of the claimant if trip ticket has an approved claim" do
        claimant = FactoryGirl.create(:provider, :name => "Some Claimant")
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => claimant, :status => :approved)
        @trip_ticket.status_for(@user).must_equal "Some Claimant Approved"
      end

      it "should return Awaiting Result if trip ticket has an approved claim and appointment time has passed" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :approved)
        @trip_ticket.tap {|t| t.appointment_time = 1.minutes.ago }.status_for(@user).must_equal 'Awaiting Result'
      end

      it "should return result status if trip ticket is resolved" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :approved)
        @trip_ticket.tap {|t| t.create_trip_result(:outcome => 'Completed') }.status_for(@user).must_equal 'Completed'
      end
    end

    describe "when current user does not belongs to originator" do
      setup do
        @trip_ticket = FactoryGirl.create(:trip_ticket, :appointment_time => 2.days.from_now)
      end

      it "should return Available if trip ticket has no claims" do
        @trip_ticket.status_for(@user).must_equal 'Available'
      end

      it "should return Available if trip ticket has only pending claims" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
        @trip_ticket.status_for(@user).must_equal 'Available'
      end

      it "should return Claim Pending if trip ticket has a claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider)
        @trip_ticket.status_for(@user).must_equal 'Claim Pending'
      end

      it "should return Declined if trip ticket has a declined claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider, :status => :declined)
        @trip_ticket.status_for(@user).must_equal 'Declined'
      end

      it "should return Claimed if trip ticket has an approved claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider, :status => :approved)
        @trip_ticket.status_for(@user).must_equal 'Claimed'
      end

      it "should return Unavailable if trip ticket has an approved claim not from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :approved)
        @trip_ticket.status_for(@user).must_equal 'Unavailable'
      end

      it "should return Unavailable if trip ticket is rescinded and has no claims from user's provider" do
        @trip_ticket.tap {|t| t.rescind! }.status_for(@user).must_equal 'Unavailable'
      end

      it "should return Rescinded if trip ticket is rescinded and has a claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider)
        @trip_ticket.tap {|t| t.rescind! }.status_for(@user).must_equal 'Rescinded'
      end

      it "should return Unavailable if trip ticket is expired" do
        @trip_ticket.tap {|t| t.expired = true }.status_for(@user).must_equal 'Unavailable'
      end

      it "should return Unavailable if trip ticket is resolved and has no claims from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :status => :approved)
        @trip_ticket.tap {|t| t.create_trip_result(:outcome => 'Completed') }.status_for(@user).must_equal 'Unavailable'
      end

      it "should return Declined if trip ticket is resolved and has a declined claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider, :status => :declined)
        @trip_ticket.tap {|t| t.create_trip_result(:outcome => 'Completed') }.status_for(@user).must_equal 'Declined'
      end

      it "should return Awaiting Result if trip ticket has an approved claim from user's provider and appointment time has passed" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider, :status => :approved)
        @trip_ticket.tap {|t| t.appointment_time = 1.minutes.ago }.status_for(@user).must_equal 'Awaiting Result'
      end

      it "should return result status if trip ticket is resolved and has an approved claim from user's provider" do
        FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => @provider, :status => :approved)
        @trip_ticket.tap {|t| t.create_trip_result(:outcome => 'Completed') }.status_for(@user).must_equal 'Completed'
      end
    end
  end

  TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES.each do |field_sym|
    describe "#{field_sym.to_s} string_array fields" do
      test "provider admins should see a single #{field_sym.to_s} field when creating a trip ticket (and can save it even w/o javascript, but cannot add more than a single new value)" do
        click_link "Tickets"
        click_link "Add New"
      
        fill_in_minimum_required_trip_ticket_fields
      
        within("##{field_sym.to_s}") do
          assert_equal 1, all('.pgStringArrayValue').size
          all('.pgStringArrayValue')[0].set('A')
        end      
      
        click_button "Create Trip ticket"

        assert page.has_content?("Trip ticket was successfully created")

        within("##{field_sym.to_s}") do
          assert_equal 2, all('.pgStringArrayValue').size # "A" + blank      
          assert page.has_selector?('.pgStringArrayValue[value=\'A\']')
        end
      end

      test "provider admins should see #{field_sym.to_s} fields when editing a trip ticket (and can modify the current values without javascript, but cannot add more than a single new value)" do
        # NOTE users can modify the current values without javascript, but cannot add more than a single new value

        trip_ticket = FactoryGirl.create(:trip_ticket, :originator => @provider)
        trip_ticket.send("#{field_sym.to_s}=".to_sym, ['A', 'B'])
        trip_ticket.save!

        visit "/trip_tickets/#{trip_ticket.id}"

        within("##{field_sym.to_s}") do
          # NOTE - we cannot predict the order of these hstore attributes
          assert page.has_selector?('.pgStringArrayValue[value=\'A\']')
          assert page.has_selector?('.pgStringArrayValue[value=\'B\']')

          find('.pgStringArrayValue[value=\'\']').set('C')
          find('.pgStringArrayValue[value=\'B\']').set('')
        end

        click_button "Update Trip ticket"

        assert page.has_content?("Trip ticket was successfully updated")

        within("##{field_sym.to_s}") do
          # PROTIP - If this fails, update the TripTicketsController#compact_string_array_params method
          assert_equal 3, all('.pgStringArrayValue').size # "A" + "B" + blank
          
          assert page.has_selector?('.pgStringArrayValue[value=\'A\']')
          assert page.has_selector?('.pgStringArrayValue[value=\'C\']')
          assert page.has_no_selector?('.pgStringArrayValue[value=\'B\']')
        end
      end

      test "users who cannot edit an existing trip ticket should see an unordered list of #{field_sym.to_s}" do
        provider_2 = FactoryGirl.create(:provider)
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => provider_2
        )
        relationship.approve!
        trip_ticket = FactoryGirl.create(:trip_ticket, :originator => provider_2)
        trip_ticket.send("#{field_sym.to_s}=".to_sym, ['A', 'B'])
        trip_ticket.save!

        visit "/trip_tickets/#{trip_ticket.id}"

        within("##{field_sym.to_s}") do
          # NOTE - we cannot predict the order of these hstore attributes
          assert page.has_no_selector?('.pgStringArrayValue[value=\'A\']')
          assert page.has_no_selector?('.pgStringArrayValue[value=\'B\']')

          assert page.has_selector?('li', :text => "A")
          assert page.has_selector?('li', :text => "B")
        end
      end
    end
  end
    
  describe "customer_identifiers hstore fields" do
    # test "provider admins can add customer identifier attributes to a new trip ticket (using javascript)" do
    #   skip "Having trouble getting user logins to work with selenium - cdb 2013-01-29"
    #   
    #   Capybara.current_driver = :selenium
    # 
    #   visit '/'
    #   fill_in 'Email', :with => @user.email
    #   fill_in 'Password', :with => @password
    #   click_button 'Sign in'
    #   
    #   # vv- here be unexercised tests -vv
    #   
    #   click_link "Tickets"
    #   click_link "Add New"
    #
    #   fill_in_minimum_required_trip_ticket_fields
    #   
    #   assert_equal 1, all('.hstoreAttributeName').size
    #   assert_equal 1, all('.hstoreAttributeValue').size
    #   click_link "Add Customer Identifier"
    #   assert_equal 2, all('.hstoreAttributeName').size
    #   assert_equal 2, all('.hstoreAttributeValue').size
    #   
    #   all('.hstoreAttributeName')[0].set('Some')
    #   all('.hstoreAttributeValue')[0].set('Thing')
    #   all('.hstoreAttributeName')[1].set('Other')
    #   all('.hstoreAttributeValue')[1].set('Thang')
    #   
    #   click_button "Create Trip ticket"
    #   
    #   assert page.has_content?("Trip ticket was successfully created")
    #   
    #   # NOTE - we cannot predict the order of these hstore attributes
    #   assert page.has_selector?('.hstoreAttributeName[value=\'some\']')
    #   assert page.has_selector?('.hstoreAttributeValue[value=\'Thing\']')
    #   assert page.has_selector?('.hstoreAttributeName[value=\'other\']')
    #   assert page.has_selector?('.hstoreAttributeValue[value=\'Thang\']')
    # end
    
    test "provider admins should see a single pair of customer identifier attribute fields when creating a trip ticket (but cannot save them without javascript)" do
      click_link "Tickets"
      click_link "Add New"
      
      within('#customer_identifiers') do
        assert_equal 1, all('.hstoreAttributeName').size
        assert_equal 1, all('.hstoreAttributeValue').size
      end      
    end

    test "provider admins should see pairs of customer identifier attribute fields when editing a trip ticket (but cannot modify the current keys or add new pairs without javascript)" do
      trip_ticket = FactoryGirl.create(:trip_ticket, :originator => @provider)
      trip_ticket.customer_identifiers = {:charlie => 'Brown', :solid => 'Gold'}
      trip_ticket.save!

      visit "/trip_tickets/#{trip_ticket.id}"
      
      within('#customer_identifiers') do
        # NOTE - we cannot predict the order of these hstore attributes
        assert page.has_selector?('.hstoreAttributeName[value=\'charlie\']')
        assert page.has_selector?('.hstoreAttributeValue[value=\'Brown\']')
        assert page.has_selector?('.hstoreAttributeName[value=\'solid\']')
        assert page.has_selector?('.hstoreAttributeValue[value=\'Gold\']')
        
        all('.hstoreAttributeValue')[0].set('Chaplin')
        all('.hstoreAttributeValue')[1].set('Waste')
      end
      
      click_button "Update Trip ticket"
      
      assert page.has_content?("Trip ticket was successfully updated")
      
      # NOTE - we cannot predict the order of these hstore attributes
      assert page.has_selector?('.hstoreAttributeValue[value=\'Chaplin\']')
      assert page.has_selector?('.hstoreAttributeValue[value=\'Waste\']')
    end

    test "authorized users can edit trip results on tickets with approved claims repeatedly" do
      trip_ticket = FactoryGirl.create(:trip_ticket, :originator => @provider)
      trip_ticket.trip_claims << FactoryGirl.create(:trip_claim, :status => :approved)
      visit trip_ticket_path(trip_ticket) 

      select "Completed", :from => "trip_result_outcome"
      fill_in "trip_result_driver_id", :with => "Bob Smith"
      click_button "Update Trip Result"

      assert page.has_content?("Trip result was successfully created")
      assert_equal trip_ticket.reload.trip_result.outcome, "Completed"
      assert_equal trip_ticket.reload.trip_result.driver_id, "Bob Smith"

      select "No-Show", :from => "trip_result_outcome"
      click_button "Update Trip Result"

      assert page.has_content?("Trip result was successfully updated")
      assert_equal trip_ticket.reload.trip_result.outcome, "No-Show"
    end

    test "users who cannot edit an existing trip ticket should see an unordered list of customer identifier attribute pairs" do
      provider_2 = FactoryGirl.create(:provider)
      relationship = ProviderRelationship.create!(
        :requesting_provider => @provider,
        :cooperating_provider => provider_2
      )
      relationship.approve!
      trip_ticket = FactoryGirl.create(:trip_ticket, :originator => provider_2)
      trip_ticket.customer_identifiers = {:charlie => 'Brown', :solid => 'Gold'}
      trip_ticket.save!

      visit "/trip_tickets/#{trip_ticket.id}"
      
      within('#customer_identifiers') do
        # NOTE - we cannot predict the order of these hstore attributes
        assert page.has_no_selector?('.hstoreAttributeName[value=\'charlie\']')
        assert page.has_no_selector?('.hstoreAttributeValue[value=\'Brown\']')
        assert page.has_no_selector?('.hstoreAttributeName[value=\'solid\']')
        assert page.has_no_selector?('.hstoreAttributeValue[value=\'Gold\']')
        
        assert page.has_selector?('li', :text => "charlie: Brown")
        assert page.has_selector?('li', :text => "solid: Gold")
      end
    end
  end

  describe "filtering" do
    setup do
      # because we use a cookie to restore previous filters, to start fresh we need to set trip ticket filters explicitly
      @reset_filters_path = "/trip_tickets/clear_filters"
      @apply_filters_path = "/trip_tickets/apply_filters"
    end

    describe "clear filters" do
      setup do
        @u1 = FactoryGirl.create(:trip_ticket, :customer_last_name => 'Jim', :originator => @provider)
      end
    
      it "provides a link to clear the search results" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'BOB'
          click_button "Search"
        end
        
        assert page.has_no_link?("", {:href => trip_ticket_path(@u1)})
        
        within('#trip_ticket_filters') do
          assert page.has_link?("Clear")
          click_link "Clear"
        end
        
        assert page.has_link?("", {:href => trip_ticket_path(@u1)})
      end
    end

    describe "remember filters" do
      setup do
        @u1 = FactoryGirl.create(:trip_ticket, :customer_last_name => 'Jim', :originator => @provider)
      end

      it "restores the previously-used filters" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Bob'
          click_button "Search"
        end

        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Bob')
        assert page.has_no_link?("", {:href => trip_ticket_path(@u1)})

        visit "/trip_tickets"

        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Bob')
        assert page.has_no_link?("", {:href => trip_ticket_path(@u1)})
      end
    end

    describe "save filters" do
      setup do
        @u1 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_last_name => 'Jim', :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
        @u2 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_last_name => 'Bob', :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
      end

      it "allows a user to save their current filters" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Jim'
          click_button "Search"
        end

        assert page.has_link?("Save current filters")
        click_link "Save current filters"
        within('#new_filter') do
          assert page.has_field?('filter_name')
          fill_in "filter_name", :with => 'super happy fun time filter'
          click_button "Save"
        end

        assert page.has_select?('saved_filter', :selected => 'super happy fun time filter')
        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Jim')
        assert page.has_link?("", {:href => trip_ticket_path(@u1)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@u2)})
      end

      it "includes any unapplied filter changes in the saved filter" do
        skip "Test requires javascript support"

        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Jim'
          click_button "Search"
        end

        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Jim')

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_address_or_phone", :with => 'Oak'
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'jim on oak'
          click_button "Save"
        end

        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Jim')
        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')
      end

      it "allows a user to update saved filter conditions" do
        skip "Test requires javascript support"

        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Jim'
          click_button "Search"
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'jim'
          click_button "Save"
        end

        fill_in "trip_ticket_filters_customer_address_or_phone", :with => 'Oak'

        assert page.has_link?("Update saved filter")
        click_link "Update saved filter"
        within('form.edit_filter') do
          click_button "Save"
        end

        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Jim')
        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')
      end

      it "allows a user to change the name of a saved filter" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Jim'
          click_button "Search"
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'gym'
          click_button "Save"
        end

        assert page.has_select?('saved_filter', :selected => 'gym')

        click_link "Update saved filter"
        within('form.edit_filter') do
          fill_in "filter_name", :with => 'jim'
          click_button "Save"
        end

        assert page.has_select?('saved_filter', :selected => 'jim')
        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'Jim')
      end

      it "allows a user to delete a saved filter" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'Jim'
          click_button "Search"
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'jim'
          click_button "Save"
        end

        assert page.has_select?('saved_filter', :selected => 'jim')
        assert page.has_selector?('input#delete_filter[type=submit]')

        click_button 'delete_filter'

        assert page.has_no_select?('saved_filter')
      end

      it "supports combining a saved filter with ad-hoc filters" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_address_or_phone", :with => 'Oak'
          click_button "Search"
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'customers on oak'
          click_button "Save"
        end

        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')

        visit @apply_filters_path + "?saved_filter=customers+on+oak&trip_ticket_filters[customer_name]=xyz"

        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')
        assert page.has_field?("trip_ticket_filters_customer_name", :with => 'xyz')
      end

      it "restores the previously-used named filter" do
        visit @reset_filters_path

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_address_or_phone", :with => 'Oak'
          click_button "Search"
        end

        click_link "Save current filters"
        within('#new_filter') do
          fill_in "filter_name", :with => 'customers on oak'
          click_button "Save"
        end

        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')

        visit "/trip_tickets"

        assert page.has_select?('saved_filter', :selected => 'customers on oak')
        assert page.has_field?("trip_ticket_filters_customer_address_or_phone", :with => 'Oak')
      end
    end

    describe "customer name filter" do
      setup do
        @u1 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob', :originator => @provider)
        @u2 = FactoryGirl.create(:trip_ticket, :customer_last_name   => 'Bob', :originator => @provider)
        @u3 = FactoryGirl.create(:trip_ticket, :customer_last_name   => 'Jim', :originator => @provider)
        @u4 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob')
      end
    
      it "returns trip tickets accessible by the current user with a matching first, middle, or last customer name" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_name", :with => 'BOB'
          click_button "Search"
        end

        assert page.has_link?("", {:href => trip_ticket_path(@u1)})
        assert page.has_link?("", {:href => trip_ticket_path(@u2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@u3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@u4)})
      end
    end
    
    describe "customer address or phone filter" do
      setup do
        @l1 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
        @l2 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_address => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
        @l3 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_address => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :pick_up_location => FactoryGirl.create(:location, :address_1 => "Oak Street"))
        @l4 = FactoryGirl.create(:trip_ticket,                           :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street",  :address_2 => ""))
        @l5 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_primary_phone => "800-555-soak")   # <- contrived, I know
        @l6 = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_emergency_phone => "555-oak-1234") # <- contrived, I know
      end
    
      it "returns trip tickets accessible by the current user with a matching customer street address or phone numbers" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_address_or_phone", :with => 'OAK'
          click_button "Search"
        end

        assert page.has_link?("", {:href => trip_ticket_path(@l1)})
        assert page.has_link?("", {:href => trip_ticket_path(@l2)})
        assert page.has_link?("", {:href => trip_ticket_path(@l5)})
        assert page.has_link?("", {:href => trip_ticket_path(@l6)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l4)})
      end
    end
    
    describe "pick up location filter" do
      setup do
        @l1 = FactoryGirl.create(:trip_ticket, :originator => @provider, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
        @l2 = FactoryGirl.create(:trip_ticket, :originator => @provider, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
        @l3 = FactoryGirl.create(:trip_ticket, :originator => @provider, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street"))
        @l4 = FactoryGirl.create(:trip_ticket,                           :pick_up_location => FactoryGirl.create(:location, :address_1 => "Oak Street",  :address_2 => ""))
      end
    
      it "returns trip tickets accessible by the current user with a matching pick up location address" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_pick_up_location", :with => 'OAK'
          click_button "Search"
        end

        assert page.has_link?("", {:href => trip_ticket_path(@l1)})
        assert page.has_link?("", {:href => trip_ticket_path(@l2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l4)})
      end
    end
    
    describe "drop off location filter" do
      setup do
        @l1 = FactoryGirl.create(:trip_ticket, :originator => @provider, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
        @l2 = FactoryGirl.create(:trip_ticket, :originator => @provider, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
        @l3 = FactoryGirl.create(:trip_ticket, :originator => @provider, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street"))
        @l4 = FactoryGirl.create(:trip_ticket,                           :drop_off_location => FactoryGirl.create(:location, :address_1 => "Oak Street",  :address_2 => ""))
      end
    
      it "returns trip tickets accessible by the current user with a matching drop off location address" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_drop_off_location", :with => 'OAK'
          click_button "Search"
        end

        assert page.has_link?("", {:href => trip_ticket_path(@l1)})
        assert page.has_link?("", {:href => trip_ticket_path(@l2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@l4)})
      end
    end
    
    describe "originating provider filter" do
      setup do
        @provider_2 = FactoryGirl.create(:provider, :name => "Google")
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_2
        )
        relationship.approve!
        @provider_3 = FactoryGirl.create(:provider, :name => "Yahoo")
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_3
        )
        relationship.approve!
        @t1 = FactoryGirl.create(:trip_ticket, :originator => @provider)
        @t2 = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
        @t3 = FactoryGirl.create(:trip_ticket, :originator => @provider_3)
        @t4 = FactoryGirl.create(:trip_ticket)
      end
    
      it "returns trip tickets accessible by the current user with matching originating providers" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          select "Microsoft", :from => "Originating Provider"
          select "Google", :from => "Originating Provider"
          click_button "Search"
        end
        
        assert page.has_link?("", {:href => trip_ticket_path(@t1)})
        assert page.has_link?("", {:href => trip_ticket_path(@t2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
      end
    end
    
    describe "claiming provider filter" do
      setup do
        @provider_2 = FactoryGirl.create(:provider, :name => "Google")
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_2
        )
        relationship.approve!
        @provider_3 = FactoryGirl.create(:provider, :name => "Yahoo")
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_3
        )
        relationship.approve!
        
        @t1 = FactoryGirl.create(:trip_ticket, :originator => @provider)
        FactoryGirl.create(:trip_claim, :trip_ticket => @t1, :claimant => @provider_2)
        
        @t2 = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
        FactoryGirl.create(:trip_claim, :trip_ticket => @t2, :claimant => @provider_3)
        
        @t3 = FactoryGirl.create(:trip_ticket, :originator => @provider)
        FactoryGirl.create(:trip_claim, :trip_ticket => @t3)
        
        @t4 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :trip_ticket => @t4, :claimant => @provider)
      end
    
      it "returns trip tickets accessible by the current user with matching claiming providers" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          select "Microsoft", :from => "Claiming Provider"
          select "Google", :from => "Claiming Provider"
          click_button "Search"
        end
        
        assert page.has_link?("", {:href => trip_ticket_path(@t1)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
      end
    end

    describe "trip ticket seats required filter" do
      before do
        @t01 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 0, :originator => @provider)
        @t02 = FactoryGirl.create(:trip_ticket, :num_attendants => 2, :customer_seats_required => 2, :num_guests => 2, :originator => @provider)
        @t03 = FactoryGirl.create(:trip_ticket, :num_attendants => 6, :customer_seats_required => 2, :num_guests => 2, :originator => @provider)
        @t04 = FactoryGirl.create(:trip_ticket, :num_attendants => 6, :customer_seats_required => 0, :num_guests => 0, :originator => @provider)
        @t05 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 6, :num_guests => 0, :originator => @provider)
        @t06 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 6, :originator => @provider)
        @t07 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 8, :originator => @provider)
        @t08 = FactoryGirl.create(:trip_ticket, :num_attendants => 1, :customer_seats_required => 1, :num_guests => 1, :originator => @provider)

        @t09 = FactoryGirl.create(:trip_ticket, :num_attendants => 2, :customer_seats_required => 2, :num_guests => 2)
        @t10 = FactoryGirl.create(:trip_ticket, :num_attendants => 6, :customer_seats_required => 0, :num_guests => 0)
      end
      
      it "returns trip tickets accessible by the current user that have no claims on them" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_seats_required_min", :with => "3"
          fill_in "trip_ticket_filters_seats_required_max", :with => "6"
          click_button "Search"
        end
        
        assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t05)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t06)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t07)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t08)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t09)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t10)})

        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_seats_required_min", :with => "3"
          fill_in "trip_ticket_filters_seats_required_max", :with => "0"
          click_button "Search"
        end
        
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t05)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t06)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t07)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t08)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t09)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t10)})
      end      
    end

    describe "scheduling priority filter" do
      setup do
        @t1 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'dropoff', :originator => @provider)
        @t2 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'pickup',  :originator => @provider)
        @t3 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'dropoff')
        @t4 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'pickup')
      end
    
      it "returns trip tickets accessible by the current user with a matching scheduling priority" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          select "Drop-off", :from => 'trip_ticket_filters_scheduling_priority'
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t1)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
      
        within('#trip_ticket_filters') do
          select "Pickup", :from => 'trip_ticket_filters_scheduling_priority'
          click_button "Search"
        end

        assert page.has_no_link?("", {:href => trip_ticket_path(@t1)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
      end
    end

    describe "trip time filter" do
      setup do
        @t1 = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => Time.zone.parse('2012-01-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
        @t2 = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => Time.zone.parse('2012-01-01'), :requested_pickup_time => '10:00', :requested_drop_off_time => '23:00')
        @t3 = FactoryGirl.create(:trip_ticket, :originator => @provider, :appointment_time => Time.zone.parse('2012-03-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
        @t4 = FactoryGirl.create(:trip_ticket,                           :appointment_time => Time.zone.parse('2012-04-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
      end
    
      it "returns trip tickets accessible by the current user with a requested_pickup_time or requested_drop_off_time between the selected times" do
        skip "Need to update backend to accept datetime string"
        
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          select "2012", :from => 'trip_ticket_filters_trip_time_start_year'
          select "January", :from => 'trip_ticket_filters_trip_time_start_month'
          select "1", :from => 'trip_ticket_filters_trip_time_start_day'
          select "11 AM", :from => 'trip_ticket_filters_trip_time_start_hour'
          select "", :from => 'trip_ticket_filters_trip_time_start_minute'

          select "2012", :from => 'trip_ticket_filters_trip_time_end_year'
          select "January", :from => 'trip_ticket_filters_trip_time_end_month'
          select "1", :from => 'trip_ticket_filters_trip_time_end_day'
          select "10 PM", :from => 'trip_ticket_filters_trip_time_end_hour'
          select "", :from => 'trip_ticket_filters_trip_time_end_minute'
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t1)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t2)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
        
        within('#trip_ticket_filters') do
          select "2012", :from => 'trip_ticket_filters_trip_time_start_year'
          select "February", :from => 'trip_ticket_filters_trip_time_start_month'
          select "1", :from => 'trip_ticket_filters_trip_time_start_day'
          select "12 PM", :from => 'trip_ticket_filters_trip_time_start_hour'
          select "", :from => 'trip_ticket_filters_trip_time_start_minute'

          select "2012", :from => 'trip_ticket_filters_trip_time_end_year'
          select "March", :from => 'trip_ticket_filters_trip_time_end_month'
          select "1", :from => 'trip_ticket_filters_trip_time_end_day'
          select "09 PM", :from => 'trip_ticket_filters_trip_time_end_hour'
          select "", :from => 'trip_ticket_filters_trip_time_end_minute'
          click_button "Search"
        end

        assert page.has_no_link?("", {:href => trip_ticket_path(@t1)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t2)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t3)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t4)})
      end
    end

    describe "customer identifiers filter" do
      setup do
        @t01 = FactoryGirl.create(:trip_ticket, :customer_identifiers                 => {'a' => 'b', 'c' => 'd'}, :originator => @provider)
        @t02 = FactoryGirl.create(:trip_ticket, :customer_eligibility_factors         => ['c', 'a'], :originator => @provider)
        @t03 = FactoryGirl.create(:trip_ticket, :customer_eligibility_factors         => ['a', 'b'])
        @t04 = FactoryGirl.create(:trip_ticket, :customer_mobility_factors            => ['b', 'c'], :originator => @provider)
        @t05 = FactoryGirl.create(:trip_ticket, :customer_mobility_factors            => ['c', 'a'])
        @t06 = FactoryGirl.create(:trip_ticket, :customer_service_animals             => ['a', 'b'], :originator => @provider)
        @t07 = FactoryGirl.create(:trip_ticket, :customer_service_animals             => ['b', 'c'])
        @t08 = FactoryGirl.create(:trip_ticket, :trip_funders                         => ['a', 'b'], :originator => @provider)
        @t09 = FactoryGirl.create(:trip_ticket, :trip_funders                         => ['b', 'c'])
      end
    
      it "returns trip tickets accessible by the current user with a matching scheduling priority" do
        visit @reset_filters_path
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_identifiers", :with => "a"
          click_button "Search"
        end
        
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t05)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t06)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t07)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t08)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t09)})
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_identifiers", :with => "b"
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t05)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t06)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t07)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t08)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t09)})
      
        within('#trip_ticket_filters') do
          fill_in "trip_ticket_filters_customer_identifiers", :with => "d"
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t05)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t06)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t07)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t08)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t09)})
      end
    end

    describe "trip ticket rescinded status filter" do
      setup do
        @t01 = FactoryGirl.create(:trip_ticket, :rescinded => false, :originator => @provider)
        @t02 = FactoryGirl.create(:trip_ticket, :rescinded => false, :originator => @provider)
        @t03 = FactoryGirl.create(:trip_ticket, :rescinded => true, :originator => @provider)
      end

      it "should not filter out rescinded trips by default" do
        visit @reset_filters_path
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should allow the rescinded trip filter to be explicitly enabled" do
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Hide rescinded", :from => "trip_ticket_filters_rescinded"
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should allow the rescinded trip filter to be disabled" do
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Show rescinded (default)", :from => "trip_ticket_filters_rescinded"
          click_button "Search"
        end

        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
      end

      it "should allow the user to filter out all except rescinded trips" do
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Only rescinded", :from => "trip_ticket_filters_rescinded"
          click_button "Search"
        end

        assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
      end
    end

    # Provider Service Filters

    describe "trip ticket eligibility requirements" do
      setup do
        @provider_2 = FactoryGirl.create(:provider)
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_2
        )
        relationship.approve!
        @service = FactoryGirl.create(:service, :provider => @provider)
        @eligibility_requirement_1 = FactoryGirl.create(:eligibility_requirement, :boolean_type => 'or', :service => @service)
      end

      describe "eligibility factors filter" do
        setup do
          @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_eligibility_factors => ['Veteran', 'Disabled'])
          @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_eligibility_factors => ['Veteran'])
          @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_eligibility_factors => ['Disabled'])
          @t04 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_eligibility_factors => nil)
        end

        let(:eligibility_rule_1) {
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_eligibility_factors',
            :comparison_type => 'equal',
            :comparison_value => 'veteran',
            :eligibility_requirement => @eligibility_requirement_1
          )
        }
        let(:eligibility_rule_2) {
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_eligibility_factors',
            :comparison_type => 'equal',
            :comparison_value => 'disabled',
            :eligibility_requirement => @eligibility_requirement_1
          )
        }

        it "should not filter out trips the provider is ineligible to fulfill by default" do
          eligibility_rule_1
          visit @reset_filters_path
          assert page.has_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("", {:href => trip_ticket_path(@t04)})
          eligibility_rule_2
          visit @reset_filters_path
          assert page.has_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("", {:href => trip_ticket_path(@t04)})
        end

        it "should allow the eligibility filter to be explicitly enabled" do
          eligibility_rule_1

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        end

        it "should support 'must not equal' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_eligibility_factors',
            :comparison_type => 'not_equal',
            :comparison_value => 'disabled',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        end

        it "should support 'must contain' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_eligibility_factors',
            :comparison_type => 'contain',
            :comparison_value => 'vet',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        end

        it "should support 'must not contain' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_eligibility_factors',
            :comparison_type => 'not_contain',
            :comparison_value => 'vet',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        end

        it "should allow the eligibility filter to be disabled" do
          eligibility_rule_1

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Do not apply service filters (default)", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        end

        it "should not cause any errors if an eligibility requirement contains no eligibility rules" do
          visit @reset_filters_path
          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("", {:href => trip_ticket_path(@t04)})
        end

        it "should never filter out a provider's own trip tickets" do
          own_trip = FactoryGirl.create(:trip_ticket, :originator => @provider, :customer_eligibility_factors => nil)
          eligibility_rule_1
          visit @reset_filters_path
          assert page.has_link?("", {:href => trip_ticket_path(own_trip)})
        end
      end

      describe "service level filter" do
        setup do
          @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => nil)
          @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => 'Stretcher')
          @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => 'Needs Stretcher')
        end

        it "should support 'must equal' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'equal',
            :comparison_value => 'stretcher',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        end

        it "should support 'must not equal' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'not_equal',
            :comparison_value => 'stretcher',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        end

        it "should support 'must contain' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'contain',
            :comparison_value => 'stretch',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        end

        it "should support 'must not contain' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'not_contain',
            :comparison_value => 'needs',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        end
      end

      describe "greater than/less than filtering" do
        setup do
          @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => nil)
          @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => '1')
          @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_service_level => '2')
        end

        it "should support 'greater than' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'greater_than',
            :comparison_value => '1',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        end

        it "should support 'less than' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_service_level',
            :comparison_type => 'less_than',
            :comparison_value => '2',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        end
      end

      describe "customer age filter" do
        setup do
          @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_dob => Date.parse('July 31, 1953')) # age 60, b-day yesterday
          @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_dob => Date.parse('August 1, 1953')) # age 60, b-day today
          @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_dob => Date.parse('July 31, 1954')) # age 59, b-day yesterday
          @t04 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :customer_dob => Date.parse('August 2, 1952')) # age 60, b-day tomorrow
          Timecop.freeze(Time.parse("Thu, 01 Aug 2013 12:00:00 +0000").in_time_zone)
        end

        after do
          Timecop.return
        end

        it "should support 'must equal' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_dob',
            :comparison_type => 'equal',
            :comparison_value => '60',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        end

        it "should support 'must not equal' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_dob',
            :comparison_type => 'not_equal',
            :comparison_value => '60',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        end

        it "should support 'greater than' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_dob',
            :comparison_type => 'greater_than',
            :comparison_value => '59',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t04)})
        end

        it "should support 'less than' filtering" do
          FactoryGirl.create(
            :eligibility_rule,
            :trip_field => 'customer_dob',
            :comparison_type => 'less_than',
            :comparison_value => '60',
            :eligibility_requirement => @eligibility_requirement_1
          )

          visit @reset_filters_path
          within('#trip_ticket_filters') do
            select "Apply service filters", :from => "trip_ticket_filters_service_filters"
            click_button "Search"
          end

          assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
          assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
          assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
        end
      end
    end

    describe "trip ticket operating hours filter" do
      setup do
        @provider_2 = FactoryGirl.create(:provider)
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_2
        )
        relationship.approve!
        @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2,
                                  :appointment_time => Time.zone.parse('Sat, 27 Jul 2013 16:00'),
                                  :requested_pickup_time => '15:00',
                                  :requested_drop_off_time => '17:00')
        @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2,
                                  :appointment_time => Time.zone.parse('Sat, 27 Jul 2013 22:00'),
                                  :requested_pickup_time => '21:00',
                                  :requested_drop_off_time => '23:00')
        @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2,
                                  :appointment_time => Time.zone.parse('Sun, 28 Jul 2013 16:00'),
                                  :requested_pickup_time => '15:00',
                                  :requested_drop_off_time => '17:00')
        @service = FactoryGirl.create(:service, :provider => @provider)
      end

      let(:operating_hours_1) {
        FactoryGirl.create(:operating_hours, day_of_week: 6, open_time: "09:00", close_time: "22:00", :service => @service)
      }
      let(:nil_operating_hours) {
        FactoryGirl.create(:operating_hours, day_of_week: 6, open_time: nil, close_time: nil, :service => @service)
      }

      it "should not filter out trips that are outside the provider's service hours by default" do
        operating_hours_1
        visit @reset_filters_path
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should allow service hour filtering to be explicitly enabled via the eligibility filter control" do
        operating_hours_1
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should filter out no trips if 24-hour service is specified" do
        FactoryGirl.create(:operating_hours, day_of_week: 0, open_time: "00:00", close_time: "00:00", :service => @service)
        FactoryGirl.create(:operating_hours, day_of_week: 6, open_time: "00:00", close_time: "00:00", :service => @service)
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should handle the case where service operating hours end after midnight" do
        FactoryGirl.create(:operating_hours, day_of_week: 0, open_time: "06:00", close_time: "02:00", :service => @service)

        t04 = FactoryGirl.create(:trip_ticket, :originator => @provider_2,
                                  :appointment_time => Time.zone.parse('Sun, 28 Jul 2013 01:00'),
                                  :requested_pickup_time => '11:00',
                                  :requested_drop_off_time => '01:00')

        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end

        assert page.has_no_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        assert page.has_link?("",    {:href => trip_ticket_path(t04)})
      end

      it "should allow service hour filtering to be disabled via the eligibility filter control" do
        operating_hours_1
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Do not apply service filters (default)", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
      end

      it "should not cause any errors if a service contains no operating hours" do
        visit @reset_filters_path
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should not cause any errors if a service contains nil operating hours" do
        nil_operating_hours
        visit @reset_filters_path
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should not filter out any trips if a service contains nil operating hours" do
        nil_operating_hours
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should not affects other service filters if a service contains nil operating hours" do
        nil_operating_hours
        operating_hours_1
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
      end

      it "should never filter out a provider's own trip tickets" do
        own_trip = FactoryGirl.create(:trip_ticket, :originator => @provider,
                                      :appointment_time => Time.zone.parse('Mon, 29 Jul 2013 22:00'),
                                      :requested_pickup_time => '21:00',
                                      :requested_drop_off_time => '23:00')
        operating_hours_1
        visit @reset_filters_path
        assert page.has_link?("", {:href => trip_ticket_path(own_trip)})
      end
    end

    describe "trip ticket service area filter" do
      setup do
        @provider_2 = FactoryGirl.create(:provider)
        relationship = ProviderRelationship.create!(
          :requesting_provider => @provider,
          :cooperating_provider => @provider_2
        )
        relationship.approve!

        @service_area = "POLYGON ((-70.6365966796875 42.60377635247125, -70.9991455078125 42.026989870279486, -71.3825439453125 42.25804908709509, -70.6365966796875 42.60377635247125))"
        @location_in_area = FactoryGirl.create(:location, :position => "POINT (-71.06266021728516 42.35664962372854)")
        @location_outside_area = FactoryGirl.create(:location, :position => "POINT (-72.0 42.0)")

        @t01 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :pick_up_location => @location_in_area, :drop_off_location => @location_in_area)
        @t02 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :pick_up_location => @location_in_area, :drop_off_location => @location_outside_area)
        @t03 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :pick_up_location => @location_outside_area, :drop_off_location => @location_in_area)
        @t04 = FactoryGirl.create(:trip_ticket, :originator => @provider_2, :pick_up_location => @location_outside_area, :drop_off_location => @location_outside_area)
      end

      let(:service_1) {
        FactoryGirl.create(:service, :provider => @provider, :service_area => @service_area, :service_area_type => 'pickup')
      }
      let(:service_2) {
        FactoryGirl.create(:service, :provider => @provider, :service_area => @service_area, :service_area_type => 'dropoff')
      }
      let(:service_3) {
        FactoryGirl.create(:service, :provider => @provider, :service_area => @service_area, :service_area_type => 'both')
      }
      let(:service_4) {
        FactoryGirl.create(:service, :provider => @provider, :service_area => @service_area, :service_area_type => 'either')
      }

      it "should not filter trips that are outside the provider's service area by default" do
        service_3
        visit @reset_filters_path
        assert page.has_link?("", {:href => trip_ticket_path(@t01)})
        assert page.has_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_link?("", {:href => trip_ticket_path(@t04)})
      end

      it "should filter trips where pickup address is not in the provider's service area" do
        service_1
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
      end

      it "should filter trips where drop-off address is not in the provider's service area" do
        service_2
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
      end

      it "should filter trips where pickup address or drop-off address is not in the provider's service area" do
        service_3
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t02)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
      end

      it "should filter trips where pickup address or drop-off address is not in the provider's service area" do
        service_4
        visit @reset_filters_path
        within('#trip_ticket_filters') do
          select "Apply service filters", :from => "trip_ticket_filters_service_filters"
          click_button "Search"
        end
        assert page.has_link?("",    {:href => trip_ticket_path(@t01)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t02)})
        assert page.has_link?("",    {:href => trip_ticket_path(@t03)})
        assert page.has_no_link?("", {:href => trip_ticket_path(@t04)})
      end
    end
  end

  describe "notifications" do
    setup do
      @partner = FactoryGirl.create(:provider, :name => "Macrohard")
      @relationship = ProviderRelationship.create!(
        :requesting_provider => @provider,
        :cooperating_provider => @partner
      )
      @relationship.approve!
      @partner_user = FactoryGirl.create(:user,
                                         :provider => @partner,
                                         :role => Role.find_or_create_by_name!("provider_admin"),
                                         :notification_preferences => NotificationRecipients::NOTIFICATION_TYPES.stringify_keys.keys)
      @acts_as_notifier_disabled = ActsAsNotifier::Config.disabled
      @acts_as_notifier_use_delayed_job = ActsAsNotifier::Config.use_delayed_job
      ActsAsNotifier::Config.disabled = false
      ActsAsNotifier::Config.use_delayed_job = false
    end

    teardown do
      ActsAsNotifier::Config.disabled = @acts_as_notifier_disabled
      ActsAsNotifier::Config.use_delayed_job = @acts_as_notifier_use_delayed_job
    end

    it "should notify partner users of new trips" do
      click_link "Tickets"
      click_link "Add New"
      fill_in_minimum_required_trip_ticket_fields
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        click_button "Create Trip ticket"
      end
      validate_last_delivery(@partner_user.email, 'Ride Connection Clearinghouse: new trip ticket')
    end

    it "should not notify users for partners in blacklist of new trips" do
      click_link "Tickets"
      click_link "Add New"
      fill_in_minimum_required_trip_ticket_fields
      select "Macrohard", :from => "Provider black list"
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        click_button "Create Trip ticket"
      end
    end
  end

  private

  def fill_in_minimum_required_trip_ticket_fields
    within('#originator') do
      fill_in "Customer ID", :with => "ABC123"
    end

    within('#pick_up_location') do
      fill_in 'Address Line 1', :with => '456 Some Place'
      fill_in 'City', :with => 'Some City'
      fill_in 'State', :with => 'ST'
      fill_in 'Postal Code', :with => '12345'
    end
  
    within('#drop_off_location') do
      fill_in 'Address Line 1', :with => '789 Some Place'
      fill_in 'City', :with => 'Some City'
      fill_in 'State', :with => 'ST'
      fill_in 'Postal Code', :with => '12345'
    end

    fill_in 'First Name', :with => 'Phil'
    fill_in 'Last Name', :with => 'Scott'
    fill_in 'Primary Phone Number', :with => '555-1212'
    select 'No', :from => 'Information Withheld?'    
    select_date 30.years.ago, :from => :trip_ticket_customer_dob
    select_datetime Time.zone.now.change(min: 0), :from => :trip_ticket_appointment_time
    select 'Pickup', :from => 'Scheduling priority'
  end

  def select_date(datetime, options = {})
    raise ArgumentError, 'from is a required option' if options[:from].blank?
    field = options[:from].to_s
    select datetime.strftime("%Y"), :from => "#{field}_1i"
    select datetime.strftime("%B"), :from => "#{field}_2i"
    select datetime.strftime("%-d"), :from => "#{field}_3i"
  end

  def select_time(datetime, options = {})  
    raise ArgumentError, 'from is a required option' if options[:from].blank?
    field = options[:from].to_s
    select datetime.strftime("%I %p"), :from => "#{field}_4i"
    select datetime.strftime("%M")   , :from => "#{field}_5i"
  end

  def select_datetime(datetime, options = {})
    select_date(datetime, options) 
    select_time(datetime, options) 
  end
end
