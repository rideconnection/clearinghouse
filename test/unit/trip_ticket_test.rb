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
    
    FactoryGirl.create(:trip_claim, :status => :pending, :trip_ticket => @trip_ticket)
    @trip_ticket.approved?.must_equal false
  
    FactoryGirl.create(:trip_claim, :status => :approved, :trip_ticket => @trip_ticket)
    @trip_ticket.approved?.must_equal true
  end
  
  it "knows if it can have a trip result" do
    assert !@trip_ticket.can_create_new_result? 
  
    FactoryGirl.create(:trip_claim, :status => :approved, :trip_ticket => @trip_ticket)
    assert @trip_ticket.can_create_new_result? 
  
    result = TripResult.new(:outcome => "Completed")
    result.trip_ticket = @trip_ticket
    result.save!
    assert !@trip_ticket.can_create_new_result? # already have a result now
    assert @trip_ticket.can_create_or_edit_result? # but can edit existing result 
  end
  
  it "knows if it has a claim from a specific provider" do
    p = FactoryGirl.create(:provider)
    FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket)
    @trip_ticket.includes_claim_from?(p).must_equal false
    FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => p)
    @trip_ticket.includes_claim_from?(p).must_equal true
  end
  
  it "should know it doesn't have a claim from a provider if the status is denied/rescinded" do
    provider = FactoryGirl.create(:provider)
    claim = FactoryGirl.create(:trip_claim, 
      :trip_ticket  => @trip_ticket, 
      :claimant     => provider
    )
    assert @trip_ticket.includes_claim_from?(provider)
  
    claim.update_attributes!(:status => :rescinded)
    assert !@trip_ticket.includes_claim_from?(provider)
    claim.update_attributes!(:status => :declined)
    assert !@trip_ticket.includes_claim_from?(provider)
  
    claim.update_attributes!(:status => :approved)
    assert @trip_ticket.includes_claim_from?(provider)
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
  
  it "should allow a trip to be rescinded" do
    @trip_ticket.rescind!
    @trip_ticket.rescinded.must_equal true
  end
  
  it "should not allow a trip with results to be rescinded" do
    trip_claim = FactoryGirl.create(:trip_claim, :status => :approved, :trip_ticket => @trip_ticket)
    result = @trip_ticket.create_trip_result(:outcome => "Completed")
    proc { @trip_ticket.rescind! }.must_raise(ActiveRecord::RecordInvalid)
  end
  
  it "should rescind pending trip claims if it is rescinded" do
    trip_claim = FactoryGirl.create(:trip_claim, :status => :pending, :trip_ticket => @trip_ticket)
    @trip_ticket.rescind!
    trip_claim.reload
    trip_claim.status.must_equal :rescinded
  end
  
  it "should create a canceled result for approved trip claims if it is rescinded" do
    trip_claim = FactoryGirl.create(:trip_claim, :status => :approved, :trip_ticket => @trip_ticket)
    @trip_ticket.rescind!
    @trip_ticket.reload
    @trip_ticket.trip_result.wont_be_nil
    @trip_ticket.trip_result.outcome.must_equal "Cancelled"
  end
  
  it "has an originated_or_claimed_by method that returns trips originated or claimed by a provider" do
    originator = @trip_ticket.originator
    claimant = FactoryGirl.create(:provider)
    random_provider = FactoryGirl.create(:provider)
    FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket, :claimant => claimant)
  
    assert_includes TripTicket.originated_or_claimed_by(originator), @trip_ticket
    assert_includes TripTicket.originated_or_claimed_by(claimant), @trip_ticket
    refute_includes TripTicket.originated_or_claimed_by(random_provider), @trip_ticket
  end
  
  TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES.each do |field_sym|
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
  
  describe "icons" do
    it "should return icon01 if keyword scooter found" do
      @trip_ticket.customer_mobility_factors = ['scooter']
      @trip_ticket.icon_list.must_include({ file: 'icon01.png', alt: 'scooter' })
    end
    it "should return icon03 if keyword walker found" do
      @trip_ticket.customer_mobility_factors = ['walker']
      @trip_ticket.icon_list.must_include({ file: 'icon03.png', alt: 'walker' })
    end
    it "should return icon04 if keyword oxygen found" do
      @trip_ticket.customer_mobility_factors = ['oxygen']
      @trip_ticket.icon_list.must_include({ file: 'icon04.png', alt: 'oxygen' })
    end
    it "should return icon07 if keyword wheelchair found" do
      @trip_ticket.customer_mobility_factors = ['wheelchair']
      @trip_ticket.icon_list.must_include({ file: 'icon07.png', alt: 'wheelchair' })
    end
    it "should return icon05 if any service animal is listed" do
      @trip_ticket.customer_service_animals = ['unicorn']
      @trip_ticket.icon_list.must_include({ file: 'icon05.png', alt: 'customer service animals' })
    end
    it "should match keywords regardless of case" do
      @trip_ticket.customer_mobility_factors = ['Walker', 'SCOOTER']
      @trip_ticket.icon_list.must_include({ file: 'icon01.png', alt: 'scooter' })
      @trip_ticket.icon_list.must_include({ file: 'icon03.png', alt: 'walker' })
    end
  end
  
  describe "white/black lists" do
    it "has an integer_array field for provider_white_list which returns an array" do
      assert_equal nil, @trip_ticket.provider_white_list
      @trip_ticket.provider_white_list = [
        '2',
        1
      ]
      @trip_ticket.save!
      @trip_ticket.reload
      # NOTE - Values are coerced to integers
      assert_equal [2, 1], @trip_ticket.provider_white_list
    end
  
    it "has an integer_array field for provider_black_list which returns an array" do
      assert_equal nil, @trip_ticket.provider_black_list
      @trip_ticket.provider_black_list = [
        '2',
        1
      ]
      @trip_ticket.save!
      @trip_ticket.reload
      # NOTE - Values are coerced to integers
      assert_equal [2, 1], @trip_ticket.provider_black_list
    end
  
    it "doesn't allow both white and black lists to be populated" do
      assert @trip_ticket.valid?
      
      @trip_ticket.provider_white_list = [1]
      @trip_ticket.provider_black_list = []
      assert @trip_ticket.valid?
      
      @trip_ticket.provider_white_list = []
      @trip_ticket.provider_black_list = [1]
      assert @trip_ticket.valid?
      
      @trip_ticket.provider_white_list = [1]
      @trip_ticket.provider_black_list = [1]
      assert !@trip_ticket.valid?
    end
    
    it "allows only integer values for provider_white_list" do
      @trip_ticket.provider_white_list = []
      assert @trip_ticket.valid?
  
      @trip_ticket.provider_white_list = ['a']
      assert !@trip_ticket.valid?
      
      @trip_ticket.provider_white_list = [:'3']
      assert !@trip_ticket.valid?
      
      @trip_ticket.provider_white_list = [1.3]
      assert !@trip_ticket.valid?
    end
    
    it "allows only integer values for provider_black_list" do
      @trip_ticket.provider_black_list = []
      assert @trip_ticket.valid?
  
      @trip_ticket.provider_black_list = ['a']
      assert !@trip_ticket.valid?
      
      @trip_ticket.provider_black_list = [:'3']
      assert !@trip_ticket.valid?
      
      @trip_ticket.provider_black_list = [1.3]
      assert !@trip_ticket.valid?
    end
  end
  
  describe "filter methods" do
    # This was mainly an issue with customer first, middle, and last names, but since we're no longer
    # using fuzzy search on those fields this special case is difficult to test for. Commenting out
    # for now.
    #
    # it "prevents fuzzy string comparisons from matching blank values" do
    #   u1 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob', :customer_middle_name => '555')
    #   u2 = FactoryGirl.create(:trip_ticket, :customer_first_name  => 'Bob', :customer_middle_name => '')
    # 
    #   results = TripTicket.filter_by_customer_name('555')
    # 
    #   assert_includes results, u1
    #   refute_includes results, u2
    # end

    it "has a filter_by_customer_name method that matches on a customer's first and/or last name, but not fuzzily" do
      u1 = FactoryGirl.create(:trip_ticket, :customer_first_name => 'Bob', :customer_last_name   => 'Jim')
      u2 = FactoryGirl.create(:trip_ticket, :customer_first_name => 'Jim', :customer_last_name   => 'Bob')
      u3 = FactoryGirl.create(:trip_ticket, :customer_first_name => 'Dan', :customer_last_name   => 'Jim')
      u4 = FactoryGirl.create(:trip_ticket, :customer_first_name => 'Dan', :customer_last_name   => 'Kim')
    
      results = TripTicket.filter_by_customer_name('jim')
    
      assert_includes results, u1
      assert_includes results, u2
      assert_includes results, u3
      refute_includes results, u4
    
      results = TripTicket.filter_by_customer_name('jim bob')
    
      refute_includes results, u1
      assert_includes results, u2
      refute_includes results, u3
      refute_includes results, u4
    end
    
    it "audits changes to itself and its location" do
      ticket = FactoryGirl.create(:trip_ticket, :customer_address => FactoryGirl.create(:location, :address_1 => "Oak Street", :address_2 => ""))
    
      assert_equal 1, ticket.audits_with_associated.length

      ticket.customer_first_name = "Charles"
      ticket.save!
      assert_equal 2, ticket.audits_with_associated.length

      location = ticket.pick_up_location
      location.address_1 = "7000 5000th Avenue"
      location.save!
      ticket.reload
      assert_equal 3, ticket.audits_with_associated.length
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
    
    it "should not filter out rescinded trip tickets by default" do
      t1 = FactoryGirl.create(:trip_ticket)
      t2 = FactoryGirl.create(:trip_ticket, :rescinded => true)
      t3 = FactoryGirl.create(:trip_ticket)
    
      results = TripTicket.filter_by_rescinded(nil)
    
      assert_includes results, t1
      assert_includes results, t2
      assert_includes results, t3
    end
    
    it "has a filter_by_rescinded method that can limit results by trip rescinded field" do
      t1 = FactoryGirl.create(:trip_ticket)
      t2 = FactoryGirl.create(:trip_ticket, :rescinded => true)
      t3 = FactoryGirl.create(:trip_ticket)
    
      results = TripTicket.filter_by_rescinded(:only_rescinded)
      refute_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
    
      results = TripTicket.filter_by_rescinded(:exclude_rescinded)
      assert_includes results, t1
      refute_includes results, t2
      assert_includes results, t3
    end
    
    describe "filter_by_claim_status" do
      before do
        # unclaimed
        @t1 = FactoryGirl.create(:trip_ticket)
    
        # one claim, not approved
        @t2 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => :pending, :trip_ticket => @t2)
        
        @t3 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => :declined, :trip_ticket => @t3)
    
        # multiple claims, pending and declined
        @t4 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => :pending,  :trip_ticket => @t4)
        FactoryGirl.create(:trip_claim, :status => :declined, :trip_ticket => @t4)
    
        # multiple claims, one approved
        @t5 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => :pending,  :trip_ticket => @t5)
        FactoryGirl.create(:trip_claim, :status => :declined, :trip_ticket => @t5)
        FactoryGirl.create(:trip_claim, :status => :pending,  :trip_ticket => @t5).approve!
    
        # one claim, approved
        @t6 = FactoryGirl.create(:trip_ticket)
        FactoryGirl.create(:trip_claim, :status => :pending, :trip_ticket => @t6).approve!
      end
      
      it "has a filter_by_claim_status method" do
        assert_respond_to TripTicket, :filter_by_claim_status
      end
      
      it "matches trip tickets which have no claims on them or which have only declined claims" do
        results = TripTicket.filter_by_claim_status(:unclaimed)
    
        assert_includes results, @t1
        refute_includes results, @t2
        assert_includes results, @t3
        refute_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "matches trip tickets which have pending claims" do
        results = TripTicket.filter_by_claim_status(:pending)
    
        refute_includes results, @t1
        assert_includes results, @t2
        refute_includes results, @t3
        assert_includes results, @t4
        refute_includes results, @t5
        refute_includes results, @t6
      end
      
      it "matches trip tickets which have approved claims" do
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
    
    it "has a filter_by_scheduling_priority method that matches on the the tickets scheduling priority" do
      t1 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'dropoff')
      t2 = FactoryGirl.create(:trip_ticket, :scheduling_priority => 'pickup')
    
      results = TripTicket.filter_by_scheduling_priority('pickup')
      
      refute_includes results, t1
      assert_includes results, t2
    
      results = TripTicket.filter_by_scheduling_priority('dropoff')
    
      assert_includes results, t1
      refute_includes results, t2
    end
    
    it "has a filter_by_trip_time method that matches on the the pickup OR drop-off times" do
      t1 = FactoryGirl.create(:trip_ticket, :appointment_time => Time.zone.parse('2012-01-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
      t2 = FactoryGirl.create(:trip_ticket, :appointment_time => Time.zone.parse('2012-01-01'), :requested_pickup_time => '10:00', :requested_drop_off_time => '23:00')
      t3 = FactoryGirl.create(:trip_ticket, :appointment_time => Time.zone.parse('2012-03-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
      t4 = FactoryGirl.create(:trip_ticket, :appointment_time => Time.zone.parse('2012-04-01'), :requested_pickup_time => '11:00', :requested_drop_off_time => '22:00')
    
      results = TripTicket.filter_by_trip_time(Time.zone.parse('2012-01-01 11:00'), Time.zone.parse('2012-01-01 22:00'))
      
      assert_includes results, t1
      refute_includes results, t2
      refute_includes results, t3
      refute_includes results, t4
    
      results = TripTicket.filter_by_trip_time(Time.zone.parse('2012-02-01 12:00'), Time.zone.parse('2012-03-01 21:00'))
    
      refute_includes results, t1
      refute_includes results, t2
      assert_includes results, t3
      refute_includes results, t4
    end
    
    it "has a filter_by_updated_at method that matches on the updated_at field and is inclusive on end date" do
      t1 = FactoryGirl.create(:trip_ticket, :updated_at => Time.zone.parse('2012-01-01 00:00'))
      t2 = FactoryGirl.create(:trip_ticket, :updated_at => Time.zone.parse('2012-02-01 00:00'))
      t3 = FactoryGirl.create(:trip_ticket, :updated_at => Time.zone.parse('2012-03-01 00:00'))
    
      results = TripTicket.filter_by_updated_at(Time.zone.parse('2012-01-01 00:00'), nil)
      refute_includes results, t1
      assert_includes results, t2
      assert_includes results, t3
    
      results = TripTicket.filter_by_updated_at(nil, Time.zone.parse('2012-02-01 00:00'))
      assert_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
    
      results = TripTicket.filter_by_updated_at(Time.zone.parse('2012-01-01 00:00'), Time.zone.parse('2012-02-01 00:00'))
      refute_includes results, t1
      assert_includes results, t2
      refute_includes results, t3
    end
    
    it "has a filter_by_customer_identifiers method that matches on hstore and string_array fields" do
      t01 = FactoryGirl.create(:trip_ticket, :customer_identifiers                 => {'a' => 'b', 'c' => 'd'})
      t02 = FactoryGirl.create(:trip_ticket, :customer_eligibility_factors         => ['c', 'a'])
      t03 = FactoryGirl.create(:trip_ticket, :customer_eligibility_factors         => ['a', 'b'])
      t04 = FactoryGirl.create(:trip_ticket, :customer_mobility_factors            => ['b', 'c'])
      t05 = FactoryGirl.create(:trip_ticket, :customer_mobility_factors            => ['c', 'a'])
      t06 = FactoryGirl.create(:trip_ticket, :customer_service_animals             => ['a', 'b'])
      t07 = FactoryGirl.create(:trip_ticket, :customer_service_animals             => ['b', 'c'])
      t08 = FactoryGirl.create(:trip_ticket, :trip_funders                         => ['a', 'b'])
      t09 = FactoryGirl.create(:trip_ticket, :trip_funders                         => ['b', 'c'])
    
      results = TripTicket.filter_by_customer_identifiers('a')
      
      assert_includes results, t01
      assert_includes results, t02
      assert_includes results, t03
      refute_includes results, t04
      assert_includes results, t05
      assert_includes results, t06
      refute_includes results, t07
      assert_includes results, t08
      refute_includes results, t09
    
      results = TripTicket.filter_by_customer_identifiers('b')
    
      assert_includes results, t01
      refute_includes results, t02
      assert_includes results, t03
      assert_includes results, t04
      refute_includes results, t05
      assert_includes results, t06
      assert_includes results, t07
      assert_includes results, t08
      assert_includes results, t09
    
      results = TripTicket.filter_by_customer_identifiers('d')
    
      assert_includes results, t01
      refute_includes results, t02
      refute_includes results, t03
      refute_includes results, t04
      refute_includes results, t05
      refute_includes results, t06
      refute_includes results, t07
      refute_includes results, t08
      refute_includes results, t09
    end
    
    describe "filter_by_ticket_status" do
      before do
        # Needs to test the following statuses:
        #   Status            Returned by:
        #   --------------- - ------------------------------------------------
        #   Approved        - originator_status (as "{claimant_name} Approved")
        #   Available       - claimant_status
        #   Awaiting Result - claimant_status, originator_status
        #   Cancelled       - claimant_status, originator_status
        #   Claim Pending   - claimant_status, originator_status (as "{claim_count} Claim(s) Pending")
        #   Claimed         - claimant_status
        #   Completed       - claimant_status, originator_status
        #   Declined        - claimant_status
        #   Expired         - originator_status
        #   No Claims       - originator_status
        #   No-Show         - claimant_status, originator_status
        #   Rescinded       - claimant_status, originator_status
        #   Unavailable     - claimant_status

        @originator = FactoryGirl.create(:provider)
        @claimant   = FactoryGirl.create(:provider)
        ProviderRelationship.create!(:requesting_provider => @originator, :cooperating_provider => @claimant).approve!

        # Approved
        @approved = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id, appointment_time: 1.month.from_now)
                    FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @approved.id).approve!

        # Available
        @available = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)

        # Awaiting Result
        @awaiting_result = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id, appointment_time: 1.day.ago)
                           FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @awaiting_result.id).approve!

        # Cancelled
        @cancelled = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                     FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @cancelled.id).approve!
                     @cancelled.reload.create_trip_result(:outcome => "Cancelled")

        # Claim Pending
        @claim_pending = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                         FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @claim_pending.id)

        # Claimed
        @claimed = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id, appointment_time: 1.month.from_now)
                   FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @claimed.id).approve!

        # Completed
        @completed = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                     FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @completed.id).approve!
                     @completed.reload.create_trip_result(:outcome => "Completed")

        # Declined
        @declined = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                    FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @declined.id).decline!

        # Expired
        @expired = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id, expired: true)

        # No Claims
        @no_claims = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)

        # No-Show
        @no_show = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                   FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @no_show.id).approve!
                   @no_show.reload.create_trip_result(:outcome => "No-Show")

        # Rescinded
        @rescinded = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                     FactoryGirl.create(:trip_claim, claimant_provider_id: @claimant.id, trip_ticket_id: @rescinded.id)
                     @rescinded.reload.rescind!

        # Unavailable #1 - rescinded without a claim from claimant
        @unavailable_1 = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                         @unavailable_1.rescind!

        # Unavailable #2 - expired when viewed by claimant
        @unavailable_2 = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id, expired: true)

        # Unavailable #3 - resolved using a claim that doesn't belong to claimant
        @unavailable_3 = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                         FactoryGirl.create(:trip_claim, trip_ticket_id: @unavailable_3.id).approve!
                         @unavailable_3.reload.create_trip_result(:outcome => "No-Show")

        # Unavailable #4 - an unresolved ticket with an approved claim that doesn't belong to the claimant
        @unavailable_4 = FactoryGirl.create(:trip_ticket, origin_provider_id: @originator.id)
                         FactoryGirl.create(:trip_claim, trip_ticket_id: @unavailable_4.id).approve!
      end
      
      it "has a filter_by_ticket_status method" do
        assert_respond_to TripTicket, :filter_by_ticket_status
      end
      
      it "matches approved tickets" do
        originator_results = TripTicket.filter_by_ticket_status("approved", @originator)
        assert_includes originator_results, @approved

        claimant_results = TripTicket.filter_by_ticket_status("approved", @claimant)
        refute_includes claimant_results, @approved
      end
      
      it "matches available tickets" do
        originator_results = TripTicket.filter_by_ticket_status("available", @originator)
        refute_includes originator_results, @available

        claimant_results = TripTicket.filter_by_ticket_status("available", @claimant)
        assert_includes claimant_results, @available
      end
      
      it "matches tickets awaiting results" do
        originator_results = TripTicket.filter_by_ticket_status("awaiting result", @originator)
        assert_includes originator_results, @awaiting_result

        claimant_results = TripTicket.filter_by_ticket_status("awaiting result", @claimant)
        assert_includes claimant_results, @awaiting_result
      end
      
      it "matches cancelled tickets" do
        originator_results = TripTicket.filter_by_ticket_status("cancelled", @originator)
        assert_includes originator_results, @cancelled

        claimant_results = TripTicket.filter_by_ticket_status("cancelled", @claimant)
        assert_includes claimant_results, @cancelled
      end
      
      it "matches tickets with a pending claim" do
        originator_results = TripTicket.filter_by_ticket_status("claim pending", @originator)
        assert_includes originator_results, @claim_pending

        claimant_results = TripTicket.filter_by_ticket_status("claim pending", @claimant)
        assert_includes claimant_results, @claim_pending
      end
      
      it "matches claimed tickets" do
        originator_results = TripTicket.filter_by_ticket_status("claimed", @originator)
        refute_includes originator_results, @claimed

        claimant_results = TripTicket.filter_by_ticket_status("claimed", @claimant)
        assert_includes claimant_results, @claimed
      end
      
      it "matches completed tickets" do
        originator_results = TripTicket.filter_by_ticket_status("completed", @originator)
        assert_includes originator_results, @completed

        claimant_results = TripTicket.filter_by_ticket_status("completed", @claimant)
        assert_includes claimant_results, @completed
      end
      
      it "matches declined tickets" do
        originator_results = TripTicket.filter_by_ticket_status("declined", @originator)
        refute_includes originator_results, @declined

        claimant_results = TripTicket.filter_by_ticket_status("declined", @claimant)
        assert_includes claimant_results, @declined
      end
      
      it "matches expired tickets" do
        originator_results = TripTicket.filter_by_ticket_status("expired", @originator)
        assert_includes originator_results, @expired

        claimant_results = TripTicket.filter_by_ticket_status("expired", @claimant)
        refute_includes claimant_results, @expired
      end
      
      it "matches tickets with no claims" do
        originator_results = TripTicket.filter_by_ticket_status("no claims", @originator)
        assert_includes originator_results, @no_claims

        claimant_results = TripTicket.filter_by_ticket_status("no claims", @claimant)
        refute_includes claimant_results, @no_claims
      end
      
      it "matches tickets with a result of no-show" do
        originator_results = TripTicket.filter_by_ticket_status("no-show", @originator)
        assert_includes originator_results, @no_show

        claimant_results = TripTicket.filter_by_ticket_status("no-show", @claimant)
        assert_includes claimant_results, @no_show
      end
      
      it "matches rescinded tickets" do
        originator_results = TripTicket.filter_by_ticket_status("rescinded", @originator)
        assert_includes originator_results, @rescinded

        claimant_results = TripTicket.filter_by_ticket_status("rescinded", @claimant)
        assert_includes claimant_results, @rescinded
      end
      
      it "matches unavailable tickets" do
        originator_results = TripTicket.filter_by_ticket_status("unavailable", @originator)
        refute_includes originator_results, @unavailable_1
        refute_includes originator_results, @unavailable_2
        refute_includes originator_results, @unavailable_3
        refute_includes originator_results, @unavailable_4

        claimant_results = TripTicket.filter_by_ticket_status("unavailable", @claimant)
        assert_includes claimant_results, @unavailable_1
        assert_includes claimant_results, @unavailable_2
        assert_includes claimant_results, @unavailable_3
        assert_includes claimant_results, @unavailable_4
      end
      
      
      it "matches multiple ticket statuses" do
        originator_results = TripTicket.filter_by_ticket_status(["no-show", "rescinded"], @originator)
        assert_includes originator_results, @no_show
        assert_includes originator_results, @rescinded

        claimant_results = TripTicket.filter_by_ticket_status(["no-show", "rescinded"], @claimant)
        assert_includes claimant_results, @no_show
        assert_includes claimant_results, @rescinded
      end
    end
  end

  describe "expire_at" do
    it "is not required" do
      trip_ticket = FactoryGirl.build(:trip_ticket, :expire_at => "")
      assert trip_ticket.valid?
    end
  
    it "must be a valid datetime string" do
      trip_ticket = FactoryGirl.build(:trip_ticket, :expire_at => "foo")
      refute trip_ticket.valid?
  
      trip_ticket.expire_at = "2008-09-10 00:00"
      assert trip_ticket.valid?
    end
  end
  
  describe "notifications" do
    setup do
      @acts_as_notifier_disabled = ActsAsNotifier::Config.disabled
      @acts_as_notifier_use_delayed_job = ActsAsNotifier::Config.use_delayed_job
      ActsAsNotifier::Config.disabled = false
      ActsAsNotifier::Config.use_delayed_job = false
      @recipients = 'aaa@example.com, bbb@example.com'
      TripTicket.all_instances.stub(:partner_users, @recipients)
      TripTicket.all_instances.stub(:claimant_users, @recipients)
      TripTicket.all_instances.stub(:originator_and_claimant_users, @recipients)
    end
  
    teardown do
      ActsAsNotifier::Config.disabled = @acts_as_notifier_disabled
      ActsAsNotifier::Config.use_delayed_job = @acts_as_notifier_use_delayed_job
      TripTicket.all_instances.unstub(:partner_users)
      TripTicket.all_instances.unstub(:claimant_users)
      TripTicket.all_instances.unstub(:originator_and_claimant_users)
    end
  
    it "should notify all partner users when a trip is created" do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        FactoryGirl.create(:trip_ticket)
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: new trip ticket')
    end
  
    it "should notify all claimant users when a trip is rescinded" do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        @trip_ticket.rescind!
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: claimed trip ticket rescinded')
    end
  
    it "should notify all originator and claimant users when a trip expires" do
      @trip_ticket.update_attributes(expire_at: 2.days.ago)
      Timecop.freeze(1.days.ago) do
        assert_difference 'ActionMailer::Base.deliveries.size', +1 do
          TripTicket.expire_tickets!
        end
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: claimed trip ticket expired')
    end
  end
end
