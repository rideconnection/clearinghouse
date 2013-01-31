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
    assert_equal nil, @trip_ticket.customer_identifiers
    @trip_ticket.customer_identifiers = {
      :Some => 'Thing',
      1 => 2
    }
    @trip_ticket.save!
    @trip_ticket.reload
    # NOTE - Keys and values are coerced to strings
    assert_equal({'Some' => 'Thing', '1' => '2'}, @trip_ticket.customer_identifiers)
  end
  
  it "has an string_array field for customer_mobility_impairments which returns an array" do
    assert_equal nil, @trip_ticket.customer_mobility_impairments
    @trip_ticket.customer_mobility_impairments = [
      :customer,
      'MOBILITY',
      1
    ]
    @trip_ticket.save!
    @trip_ticket.reload
    # NOTE - Values are coerced to strings
    assert_equal ['customer', 'MOBILITY', '1'], @trip_ticket.customer_mobility_impairments
  end
  
  it "has an string_array field for customer_eligibility_factors which returns an array" do
    assert_equal nil, @trip_ticket.customer_eligibility_factors
    @trip_ticket.customer_eligibility_factors = [
      :customer,
      'ELIGIBILITY',
      1
    ]
    @trip_ticket.save!
    @trip_ticket.reload
    # NOTE - Values are coerced to strings
    assert_equal ['customer', 'ELIGIBILITY', '1'], @trip_ticket.customer_eligibility_factors
  end
end
