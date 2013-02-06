require 'test_helper'

class TripTicketsTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @password = "password 1"

    @user = FactoryGirl.create(:user, 
      :password => @password, 
      :password_confirmation => @password, 
      :provider => @provider)
    @user.roles = [Role.find_or_create_by_name!("provider_admin")]
    @user.save!

    login_as @user, :scope => :user
    visit '/'
  end

  teardown do
    # For selectively enabling selenium driven tests
    # Capybara.current_driver = nil # reset
  end
  
  test "provider admins can create new trip tickets" do
    click_link "Trip Tickets"
    click_link "New Trip ticket"
    
    fill_in_minimum_required_trip_ticket_fields

    fill_in "Ethnicity", :with => "Not of Hispanic Origin"
    fill_in "Race", :with => "Asian"

    fill_in "Trip Purpose", :with => "Some information"
    
    click_button "Create Trip ticket"
    
    assert page.has_content?("Trip ticket was successfully created")
  end

 
  TripTicket::ARRAY_FIELD_NAMES.each do |field_sym|
    describe "#{field_sym.to_s} string_array fields" do
      test "provider admins should see a single #{field_sym.to_s} field when creating a trip ticket (and can save it even w/o javascript, but cannot add more than a single new value)" do
        click_link "Trip Tickets"
        click_link "New Trip ticket"
      
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
    #   click_link "Trip Tickets"
    #   click_link "New Trip ticket"
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
      click_link "Trip Tickets"
      click_link "New Trip ticket"
      
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

  private

  def fill_in_minimum_required_trip_ticket_fields
    within('#customer') do
      fill_in 'Address Line 1', :with => '123 Some Place'
      fill_in 'City', :with => 'Some City'
      fill_in 'State', :with => 'ST'
      fill_in 'Postal Code', :with => '12345'
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
    select 'Pickup', :from => 'Scheduling priority'
  end

  def select_date(date, options = {})  
    raise ArgumentError, 'from is a required option' if options[:from].blank?
    field = options[:from].to_s
    select date.year.to_s,               :from => "#{field}_1i"
    select Date::MONTHNAMES[date.month], :from => "#{field}_2i"
    select date.day.to_s,                :from => "#{field}_3i"
  end
end
