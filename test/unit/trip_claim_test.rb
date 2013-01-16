require 'test_helper'

class TripClaimTest < ActiveSupport::TestCase
  it "is valid" do
    tc = TripClaim.new(
      :claimant_provider_id => 1, 
      :claimant_service_id => 1,
      :rate => "1.23", 
      :status => "Pending", 
      :trip_ticket_id => 1
    )
    tc.valid?.must_equal true
  end
end
