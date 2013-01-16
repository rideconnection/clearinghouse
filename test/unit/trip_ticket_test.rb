require 'test_helper'

class TripTicketTest < ActiveSupport::TestCase
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
end
