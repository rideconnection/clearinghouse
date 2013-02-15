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
  
  it "knows if it has an approved claim" do
    @trip_ticket.approved?.must_equal false
    
    FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @trip_ticket)
    @trip_ticket.approved?.must_equal false

    FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:approved], :trip_ticket => @trip_ticket)
    @trip_ticket.approved?.must_equal true
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
  
  describe "scopes" do
    before do
      TripTicket.destroy_all
      
      # unclaimed
      @t1 = FactoryGirl.create(:trip_ticket)

      # one claim, not approved
      @t2 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @t2)
      
      @t3 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t3)

      # multiple claims, none approved
      @t4 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t4)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t4)

      # multiple claims, one approved
      @t5 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t5)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t5)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t5).approve!

      # one claim, approved
      @t6 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @t6).approve!
    end
    
    describe "approved" do
      it "has an approved scope" do
        assert_respond_to TripTicket, :approved
        assert_equal "ActiveRecord::Relation", TripTicket.approved.class.name
      end
      
      it "returns only approved records" do
        results = TripTicket.approved

        refute_includes results, @t1
        refute_includes results, @t2
        refute_includes results, @t3
        refute_includes results, @t4
        assert_includes results, @t5
        assert_includes results, @t6
      end
      
      it "returns an empty result set if no tickets match" do
        @t5.destroy
        @t6.destroy
        
        assert_equal [], TripTicket.approved
      end
    end

    describe "unclaimed" do
      it "has an unclaimed scope" do
        assert_respond_to TripTicket, :unclaimed
        assert_equal "ActiveRecord::Relation", TripTicket.unclaimed.class.name
      end
      
      it "returns only unclaimed records" do
        results = TripTicket.unclaimed

        assert_includes results, @t1
        refute_includes results, @t2
        refute_includes results, @t3
        refute_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "returns an empty result set if no tickets match" do
        @t1.destroy
        
        assert_equal [], TripTicket.unclaimed
      end
    end

    describe "unapproved" do
      it "has an unapproved scope" do
        assert_respond_to TripTicket, :unapproved
        assert_equal "ActiveRecord::Relation", TripTicket.unapproved.class.name
      end
      
      it "returns only claimed but unapproved records" do
        results = TripTicket.unapproved

        refute_includes results, @t1
        assert_includes results, @t2
        assert_includes results, @t3
        assert_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "returns an empty result set if no tickets match" do
        @t2.destroy
        @t3.destroy
        @t4.destroy
        
        assert_equal [], TripTicket.unapproved
      end
    end
  end

  describe "filter methods" do
    it "prevents fuzzy string comparisons from matching blank values" do
      u1 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob', :customer_middle_name => '555')
      u2 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob', :customer_middle_name => '')
    
      results = TripTicket.filter_by_customer_name('555')
    
      assert_includes results, u1
      refute_includes results, u2
    end

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

    it "has a filter_by_originating_provider method that matches on the trip ticket originator" do
      provider_1 = FactoryGirl.create(:provider)
      provider_2 = FactoryGirl.create(:provider)
      t1 = FactoryGirl.create(:trip_ticket, :originator => provider_1)
      t2 = FactoryGirl.create(:trip_ticket, :originator => provider_2)
      t3 = FactoryGirl.create(:trip_ticket)
    
      results = TripTicket.filter_by_originating_provider(provider_1.id)
    
      assert_includes results, t1
      refute_includes results, t2
      refute_includes results, t3
    
      results = TripTicket.filter_by_originating_provider([provider_1.id, provider_2.id])
    
      assert_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
    end

    it "has a filter_by_claiming_provider method that matches trip ticket trip claim claimants" do
      provider_1 = FactoryGirl.create(:provider)
      provider_2 = FactoryGirl.create(:provider)
      t1 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :trip_ticket => t1, :claimant => provider_1)
      t2 = FactoryGirl.create(:trip_ticket)
      FactoryGirl.create(:trip_claim, :trip_ticket => t2, :claimant => provider_2)
      t3 = FactoryGirl.create(:trip_ticket)
    
      results = TripTicket.filter_by_claiming_provider(provider_1.id)
    
      assert_includes results, t1
      refute_includes results, t2
      refute_includes results, t3
    
      results = TripTicket.filter_by_claiming_provider([provider_1.id, provider_2.id])
    
      assert_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
    end
    
    describe "filter_by_claim_status" do
      before do
        # unclaimed
        @t1 = FactoryGirl.create(:trip_ticket)

        # one claim, not approved
        @t2 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @t2)
        
        @t3 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t3)

        # multiple claims, none approved
        @t4 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t4)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t4)

        # multiple claims, one approved
        @t5 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t5)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:declined], :trip_ticket => @t5)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending],  :trip_ticket => @t5).approve!

        # one claim, approved
        @t6 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => TripClaim::STATUS[:pending], :trip_ticket => @t6).approve!
      end
      
      it "has a filter_by_claim_status method" do
        assert_respond_to TripTicket, :filter_by_claim_status
      end
      
      it "matches trip tickets that have no claims on them" do
        results = TripTicket.filter_by_claim_status(:unclaimed)
    
        assert_includes results, @t1
        refute_includes results, @t2
        refute_includes results, @t3
        refute_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "matches trip tickets that have claims, but none approved" do
        results = TripTicket.filter_by_claim_status(:unapproved)

        refute_includes results, @t1
        assert_includes results, @t2
        assert_includes results, @t3
        assert_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "matches trip tickets that have an approved claim" do
        results = TripTicket.filter_by_claim_status(:approved)

        refute_includes results, @t1
        refute_includes results, @t2
        refute_includes results, @t3
        refute_includes results, @t4
        assert_includes results, @t5
        assert_includes results, @t6
      end

      it "it returns nil with an invalid filter type" do
        assert_nil TripTicket.filter_by_claim_status("")
        assert_nil TripTicket.filter_by_claim_status(:foo)
      end      
    end

    it "has a filter_by_seats_required method that matches on the combined number of seats required" do
      t1 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 0)
      t2 = FactoryGirl.create(:trip_ticket, :num_attendants => 2, :customer_seats_required => 2, :num_guests => 2)
      t3 = FactoryGirl.create(:trip_ticket, :num_attendants => 6, :customer_seats_required => 2, :num_guests => 2)
      t4 = FactoryGirl.create(:trip_ticket, :num_attendants => 6, :customer_seats_required => 0, :num_guests => 0)
      t5 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 6, :num_guests => 0)
      t6 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 6)
      t7 = FactoryGirl.create(:trip_ticket, :num_attendants => 0, :customer_seats_required => 0, :num_guests => 8)
      t8 = FactoryGirl.create(:trip_ticket, :num_attendants => 1, :customer_seats_required => 1, :num_guests => 1)
    
      results = TripTicket.filter_by_seats_required({:min => 3, :max => 6})
    
      refute_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
      assert_includes results, t4
      assert_includes results, t5
      assert_includes results, t6
      refute_includes results, t7
      assert_includes results, t8
    
      results = TripTicket.filter_by_seats_required({:min => 3, :max => 0})
    
      assert_includes results, t1
      refute_includes results, t2
      refute_includes results, t3
      refute_includes results, t4
      refute_includes results, t5
      refute_includes results, t6
      refute_includes results, t7
      assert_includes results, t8
    end
  end
end
