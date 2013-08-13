require 'test_helper'

class TripClaimTest < ActiveSupport::TestCase
  setup do
    @valid_attributes = {
      :claimant_provider_id => 1, 
      :proposed_fare => "1.23", 
      :proposed_pickup_time => DateTime.now, 
      :status => "pending", 
      :trip_ticket_id => 1,
      :claimant_trip_id => "ABC123"      
    }
  end
  
  it "is valid" do
    tc = TripClaim.new(@valid_attributes)
    tc.valid?.must_equal true
  end
  
  it "has a contant that defines possible status codes" do
    assert_equal TripClaim::STATUS, [
      :pending,
      :approved,
      :declined,
      :rescinded,
    ]
  end
  
  it "requires status to be present and one of the pre-defined status codes" do
    tc = TripClaim.new(@valid_attributes.except(:status))
    tc.valid?.must_equal false
    tc.errors[:status].must_include "can't be blank"
    
    tc.status = "foo"
    tc.valid?.must_equal false
    tc.errors[:status].must_include "is not included in the list"
  end

  it "knows if it's been approved" do
    tc = TripClaim.new
    tc.approved?.must_equal false
    tc.status = :pending
    tc.approved?.must_equal false
    tc.status = :approved
    tc.approved?.must_equal true
  end
  
  it "knows if it's editable" do
    tc = TripClaim.new
    tc.editable?.must_equal true
    tc.status = :pending
    tc.editable?.must_equal true
    tc.status = :approved
    tc.editable?.must_equal false
  end
  
  it "cannot be created or modified once the parent trip ticket has been claimed" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p, :status => :approved)
    c2 = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c2.valid?.must_equal false
    c2.errors[:base].must_include "You cannot create or modify a claim on a trip ticket once it has an approved claim"
  end

  it "cannot be created if the parent trip ticket has been rescinded" do
    t = FactoryGirl.create(:trip_ticket, :rescinded => true)
    p = FactoryGirl.create(:provider)
    c = FactoryGirl.build(:trip_claim, :trip_ticket => t, :claimant => p)
    c.valid?.must_equal false
    c.errors[:base].must_include "You cannot submit a claim on a trip ticket that has been rescinded"
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
    c1.status.must_equal :declined        
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
    c1.status.must_equal :approved
  end
  
  it "can be rescinded" do
    t = FactoryGirl.create(:trip_ticket)
    p = FactoryGirl.create(:provider)
    c1 = FactoryGirl.create(:trip_claim, :trip_ticket => t, :claimant => p)

    c1.rescind!
    c1.status.must_equal :rescinded
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
    c2.status.must_equal :declined        
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

  describe "notifications" do
    setup do
      @acts_as_notifier_disbled = ActsAsNotifier::Config.disabled
      @acts_as_notifier_use_delayed_job = ActsAsNotifier::Config.use_delayed_job
      ActsAsNotifier::Config.disabled = false
      ActsAsNotifier::Config.use_delayed_job = false
      @recipients = 'aaa@example.com, bbb@example.com'
      TripClaim.all_instances.stub(:provider_users, @recipients)
    end

    teardown do
      ActsAsNotifier::Config.disabled = @acts_as_notifier_disbled
      ActsAsNotifier::Config.use_delayed_job = @acts_as_notifier_use_delayed_job
      TripClaim.all_instances.unstub(:provider_users)
    end

    it "should notify trip ticket originator users when a new claim is pending" do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        FactoryGirl.create(:trip_claim)
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket claim awaiting approval')
    end

    it "should notify trip ticket originator and claimant users when a new claim is auto-approved" do
      TripClaim.all_instances.stub(:can_be_auto_approved?, true) do
        assert_difference 'ActionMailer::Base.deliveries.size', +1 do
          FactoryGirl.create(:trip_claim)
        end
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket claim auto-approved')
    end

    it "should notify claimant users when a pending claim is approved" do
      claim = FactoryGirl.create(:trip_claim)
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        claim.approve!
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket claim approved')
    end

    it "should notify claimant users when a pending claim is declined" do
      claim = FactoryGirl.create(:trip_claim)
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        claim.decline!
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket claim declined')
    end

    it "should notify trip ticket originator users when a claim is rescinded" do
      claim = FactoryGirl.create(:trip_claim)
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        claim.rescind!
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket claim rescinded')
    end
  end
end
