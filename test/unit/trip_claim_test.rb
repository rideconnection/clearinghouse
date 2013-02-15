require 'test_helper'

class TripClaimTest < ActiveSupport::TestCase
  it "is valid" do
    tc = TripClaim.new(
      :claimant_provider_id => 1, 
      :proposed_fare => "1.23", 
      :proposed_pickup_time => DateTime.now, 
      :status => "Pending", 
      :trip_ticket_id => 1,
      :claimant_trip_id => "ABC123",
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
  
  it "knows if it's editable" do
    tc = TripClaim.new
    tc.editable?.must_equal true
    tc.status = TripClaim::STATUS[:pending]
    tc.editable?.must_equal true
    tc.status = TripClaim::STATUS[:approved]
    tc.editable?.must_equal false
  end
  
  it "cannot be created or modified once the parent trip ticket has been claimed" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p, :status => TripClaim::STATUS[:approved])
    c2 = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c2.valid?.must_equal false
    c2.errors[:base].must_include "You cannot create or modify a claim on a trip ticket once it has an approved claim"
  end
  
  it "can only belong to one ticket per provider" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)
    c2 = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c2.valid?.must_equal false
    c2.errors[:base].must_include "You may only create one claim per ticket per provider"
  end
  
  it "can be declined" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)
    c1.decline!
    c1.status.must_equal TripClaim::STATUS[:declined]        
  end
  
  it "can't be declined if the associated trip ticket already has an approved claim" do
    t = FactoryGirl.create(:trip_ticket)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t)
    c2 = FactoryGirl.create(:trip_claim, :trip_ticket => t)
    c1.approve!
    failed_val = lambda { c2.decline! }
    failed_val.must_raise ActiveRecord::RecordInvalid
    error = failed_val.call rescue $!
    error.message.must_include "You cannot create or modify a claim on a trip ticket once it has an approved claim"
  end
  
  it "can be approved" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)
    c1.approve!
    c1.status.must_equal TripClaim::STATUS[:approved]        
  end
  
  it "can't be approved if the associated trip ticket already has an approved claim" do
    t = FactoryGirl.create(:trip_ticket)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t)
    c2 = FactoryGirl.create(:trip_claim, :trip_ticket => t)
    c1.approve!
    failed_val = lambda { c2.approve! }
    failed_val.must_raise ActiveRecord::RecordInvalid
    error = failed_val.call rescue $!
    error.message.must_include "You cannot create or modify a claim on a trip ticket once it has an approved claim"
  end
  
  it "sets all other claims to 'declined' when approved" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)
    c2 = FactoryGirl.create(:trip_claim, :trip_ticket => t)
    c1.approve!
    c2.reload
    c2.status.must_equal TripClaim::STATUS[:declined]        
  end
  
  it "won't be automatically approved if the provider relationship does not allow" do
    p1 = FactoryGirl.create(:provider)
    p2 = FactoryGirl.create(:provider)
    r = ProviderRelationship.create!(
      :requesting_provider => p1,
      :cooperating_provider => p2,
      :automatic_requester_approval => false,
      :automatic_cooperator_approval => false,
      :approved_at => Time.now
    )
    tt = FactoryGirl.create(:trip_ticket, :originator => p1)
    tc = FactoryGirl.create(:trip_claim, :trip_ticket => tt, :claimant => p2)
    assert_equal false, tc.approved?, "Expected trip claim to not be approved"
    assert_equal false, tt.approved?, "Expected trip ticket to not be approved"
  end
  
  it "will be automatically approved if the provider relationship allows" do
    p1 = FactoryGirl.create(:provider)
    p2 = FactoryGirl.create(:provider)
    r = ProviderRelationship.create!(
      :requesting_provider => p1,
      :cooperating_provider => p2,
      :automatic_requester_approval => false,
      :automatic_cooperator_approval => true,
      :approved_at => Time.now
    )
    
    tt = FactoryGirl.create(:trip_ticket, :originator => p1)
    tc = FactoryGirl.create(:trip_claim, :trip_ticket => tt, :claimant => p2)
    assert_equal true, tc.approved?, "Expected trip claim to be approved"
    assert_equal true, tt.approved?, "Expected trip ticket to be approved"

    # Auto approval flags should not be interchangable
    tt = FactoryGirl.create(:trip_ticket, :originator => p2)
    tc = FactoryGirl.create(:trip_claim, :trip_ticket => tt, :claimant => p1)
    assert_equal false, tc.approved?, "Expected trip claim to not be approved"
    assert_equal false, tt.approved?, "Expected trip ticket to not be claimed"

    # The reverse should work
    r.automatic_requester_approval = true
    r.automatic_cooperator_approval = false
    r.save!
    
    tt = FactoryGirl.create(:trip_ticket, :originator => p2)
    tc = FactoryGirl.create(:trip_claim, :trip_ticket => tt, :claimant => p1)
    assert_equal true, tc.approved?, "Expected trip claim to be approved"
    assert_equal true, tt.approved?, "Expected trip ticket to be claimed"
  end
end
