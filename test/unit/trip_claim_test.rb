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

  it "knows if it's been approved" do
    tc = TripClaim.new
    tc.approved?.must_equal false
    tc.status = TripClaim::STATUS[:pending]
    tc.approved?.must_equal false
    tc.status = TripClaim::STATUS[:approved]
    tc.approved?.must_equal true
  end
  
  it "cannot be created or modified once the parent trip ticket has been claimed" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p, :status => TripClaim::STATUS[:approved])
    c2 = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c2.valid?.must_equal false
    c2.errors[:base].must_include "You cannot create or modify a claim on a trip ticket once it has been claimed"
  end
  
  it "can only belong to one ticket per provider" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)
    c2 = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c2.valid?.must_equal false
    c2.errors[:base].must_include "You may only create one claim per ticket per provider"
  end
end
