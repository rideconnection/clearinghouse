require 'test_helper'

class TripTicketTest < ActiveSupport::TestCase
  setup do
    @trip_ticket = FactoryGirl.create(:trip_ticket)
  end
  
  it "returns the customer's full name" do
    t = TripTicket.new
    t.customer_first_name = "Billy"
    t.customer_middle_name = "Bob"
    t.customer_last_name = "Bunson"
    t.customer_full_name.must_equal "Billy Bob Bunson"
    t.customer_middle_name = ""
    t.customer_full_name.must_equal "Billy Bunson"
  end
  
  it "initializes new instances with prefilled values" do
    t = TripTicket.new
    t.allowed_time_variance.must_equal -1
    t.customer_boarding_time.must_equal 0
    t.customer_deboarding_time.must_equal 0
    t.customer_seats_required.must_equal 1
    t.num_attendants.must_equal 0
    t.num_guests.must_equal 0
  end
  
  it "knows if it's been claimed" do
    @trip_ticket.claimed?.must_equal false
    FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @trip_ticket)
    @trip_ticket.claimed?.must_equal false
    FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:approved], :trip_ticket => @trip_ticket)
    @trip_ticket.claimed?.must_equal true
  end
  
  it "knows if it has a claim from a specific provider" do
    p = FactoryGirl.create(:provider)
    FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
    @trip_ticket.includes_claim_from?(p).must_equal false
    FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => p)
    @trip_ticket.includes_claim_from?(p).must_equal true
  end
  
  it "has an hstore field for customer_identifiers which returns a hash" do
    assert_equal({}, @trip_ticket.customer_identifiers)
    @trip_ticket.customer_identifiers = {
      :Some => 'Thing',
      1 => 2
    }
    @trip_ticket.save!
    @trip_ticket.reload
    # NOTE - Keys and values are coerced to strings
    assert_equal({'Some' => 'Thing', '1' => '2'}, @trip_ticket.customer_identifiers)
  end
  
  TripTicket::ARRAY_FIELD_NAMES.each do |field_sym|
    it "has an string_array field for #{field_sym.to_s} which returns an array" do
      assert_equal nil, @trip_ticket.send(field_sym)
      @trip_ticket.send("#{field_sym.to_s}=".to_sym, [
        :a,
        'B',
        1
      ])
      @trip_ticket.save!
      @trip_ticket.reload
      # NOTE - Values are coerced to strings
      assert_equal ['a', 'B', '1'], @trip_ticket.send(field_sym)
    end
  end
  
  describe "filter methods" do
    it "has a filter_by_customer_name method that matches on a customer's first, middle, and last name" do
      u1 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob')
      u2 = FactoryGirl.create(:trip_ticket, :customer_middle_name => 'Bob')
      u3 = FactoryGirl.create(:trip_ticket, :customer_last_name   => 'Bob')
      u4 = FactoryGirl.create(:trip_ticket, :customer_last_name   => 'Jim')
    
      results = TripTicket.filter_by_customer_name('bob')
    
      assert_includes results, u1
      assert_includes results, u2
      assert_includes results, u3
      refute_includes results, u4
    end

    it "has a filter_by_customer_address_or_phone method that matches on the customer address association's address_1 or address_2, or on the customer's primary or emergency phone numbers" do
      l1 = FactoryGirl.create(:trip_ticket, :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
      l2 = FactoryGirl.create(:trip_ticket, :customer_address => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
      l3 = FactoryGirl.create(:trip_ticket, :customer_address => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :pick_up_location => FactoryGirl.create(:location, :address_1 => "Oak Street"))
      l4 = FactoryGirl.create(:trip_ticket, :customer_primary_phone => "800-555-soak")   # <- contrived, I know
      l5 = FactoryGirl.create(:trip_ticket, :customer_emergency_phone => "555-oak-1234") # <- contrived, I know
    
      results = TripTicket.filter_by_customer_address_or_phone('oak')
    
      assert_includes results, l1
      assert_includes results, l2
      assert_includes results, l4
      assert_includes results, l5
      refute_includes results, l3
    end

    it "has a filter_by_pick_up_location method that matches on the pickup location association's address_1 or address_2" do
      l1 = FactoryGirl.create(:trip_ticket, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
      l2 = FactoryGirl.create(:trip_ticket, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
      l3 = FactoryGirl.create(:trip_ticket, :pick_up_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street"))
    
      results = TripTicket.filter_by_pick_up_location('oak')
    
      assert_includes results, l1
      assert_includes results, l2
      refute_includes results, l3
    end

    it "has a filter_by_pick_up_location method that matches on the dropoff location association's address_1 or address_2" do
      l1 = FactoryGirl.create(:trip_ticket, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
      l2 = FactoryGirl.create(:trip_ticket, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => "Oak Suite"))
      l3 = FactoryGirl.create(:trip_ticket, :drop_off_location => FactoryGirl.create(:location, :address_1 => "Some Street", :address_2 => ""), :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street"))
    
      results = TripTicket.filter_by_drop_off_location('oak')
    
      assert_includes results, l1
      assert_includes results, l2
      refute_includes results, l3
    end
  end
end
