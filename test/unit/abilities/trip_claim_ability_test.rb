require 'test_helper'

class TripClaimAbilityTest < ActiveSupport::TestCase
  setup do
    @roles = {
      :site_admin     => FactoryGirl.create(:role, :name => "site_admin"),
      :provider_admin => FactoryGirl.create(:role, :name => "provider_admin"),
      :scheduler      => FactoryGirl.create(:role, :name => "scheduler"),
      :dispatcher     => FactoryGirl.create(:role, :name => "dispatcher"),
      :read_only      => FactoryGirl.create(:role, :name => "read_only")
    }

    @provider_1 = FactoryGirl.create(:provider)
    @provider_2 = FactoryGirl.create(:provider)
    @provider_3 = FactoryGirl.create(:provider)

    @provider_relationship_1 = ProviderRelationship.create!(:requesting_provider => @provider_1, :cooperating_provider => @provider_2)
    @provider_relationship_2 = ProviderRelationship.create!(:requesting_provider => @provider_2, :cooperating_provider => @provider_3)
    @provider_relationship_3 = ProviderRelationship.create!(:requesting_provider => @provider_3, :cooperating_provider => @provider_1)
    @provider_relationship_1.approve!
    @provider_relationship_2.approve!

    @trip_ticket_1  = FactoryGirl.create(:trip_ticket, :originator => @provider_1)
    @trip_claim_1_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_1, :claimant => @provider_2, :status => :pending)

    @trip_ticket_2  = FactoryGirl.create(:trip_ticket, :originator => @provider_1)
    @trip_claim_2_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_2, :claimant => @provider_2, :status => :approved)

    @trip_ticket_3  = FactoryGirl.create(:trip_ticket, :originator => @provider_2)

    @trip_ticket_4  = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
    @trip_claim_4_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_4, :claimant => @provider_1, :status => :pending)
    @trip_claim_4_2 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_4, :claimant => @provider_3, :status => :approved)

    @trip_ticket_5  = FactoryGirl.create(:trip_ticket, :originator => @provider_3)

    @trip_ticket_6  = FactoryGirl.create(:trip_ticket, :originator => @provider_3)
    @trip_claim_6_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_6, :claimant => @provider_2, :status => :approved)

    # All users can read trip ticket claims that belong to their own provider or belong to trip tickets that belong to their own provider
    # Schedulers and above can create, rescind, and update trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets
    # Schedulers and above can approve and decline trip claims belonging to trip tickets that belong to their own provider
    # No user can destroy trip claims
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip claims that belong to their own provider or belong to trip tickets that belong to their own provider" do
      accessible = TripClaim.accessible_by(@site_admin)
      accessible.must_include @trip_claim_1_1
      accessible.must_include @trip_claim_2_1
      accessible.must_include @trip_claim_4_1
      accessible.wont_include @trip_claim_4_2
      accessible.wont_include @trip_claim_6_1
    end
    
    it "can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @site_admin.cannot?(:create, TripClaim.new)
      assert @site_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
      assert @site_admin.can?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
      assert @site_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
      assert @site_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      assert @site_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
    end
    
    it "can read trip claims belonging to their own provider or belonging to trip_tickets that belong to their own provider" do
      assert @site_admin.can?(:read, @trip_claim_1_1)
      assert @site_admin.can?(:read, @trip_claim_2_1)
      assert @site_admin.can?(:read, @trip_claim_4_1)    
      assert @site_admin.cannot?(:read, @trip_claim_4_2)
      assert @site_admin.cannot?(:read, @trip_claim_6_1)
    end
    
    it "can update trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @site_admin.cannot?(:update, @trip_claim_1_1)
      assert @site_admin.cannot?(:update, @trip_claim_2_1)
      assert @site_admin.can?(:update, @trip_claim_4_1)
      assert @site_admin.cannot?(:update, @trip_claim_4_2)
      assert @site_admin.cannot?(:update, @trip_claim_6_1)
    end
    
    it "cannot destroy any trip claims" do
      assert @site_admin.cannot?(:destroy, @trip_claim_1_1)
      assert @site_admin.cannot?(:destroy, @trip_claim_2_1)
      assert @site_admin.cannot?(:destroy, @trip_claim_4_1)
      assert @site_admin.cannot?(:destroy, @trip_claim_4_2)
      assert @site_admin.cannot?(:destroy, @trip_claim_6_1)
    end

    it "can rescind trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @site_admin.cannot?(:rescind, @trip_claim_1_1)
      assert @site_admin.cannot?(:rescind, @trip_claim_2_1)
      assert @site_admin.can?(:rescind, @trip_claim_4_1)
      assert @site_admin.cannot?(:rescind, @trip_claim_4_2)
      assert @site_admin.cannot?(:rescind, @trip_claim_6_1)
    end
    
    it "can approve trip claims belonging to trip tickets that belong to their own provider" do
      assert @site_admin.can?(:approve, @trip_claim_1_1)
      assert @site_admin.can?(:approve, @trip_claim_2_1)    
      assert @site_admin.cannot?(:approve, @trip_claim_4_1)
      assert @site_admin.cannot?(:approve, @trip_claim_4_2)
      assert @site_admin.cannot?(:approve, @trip_claim_6_1)
    end
    
    it "can decline trip claims belonging to trip tickets that belong to their own provider" do
      assert @site_admin.can?(:decline, @trip_claim_1_1)
      assert @site_admin.can?(:decline, @trip_claim_2_1)
      assert @site_admin.cannot?(:decline, @trip_claim_4_1)
      assert @site_admin.cannot?(:decline, @trip_claim_4_2)
      assert @site_admin.cannot?(:decline, @trip_claim_6_1)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip claims that belong to their own provider or belong to trip tickets that belong to their own provider" do
      accessible = TripClaim.accessible_by(@provider_admin)
      accessible.must_include @trip_claim_1_1
      accessible.must_include @trip_claim_2_1
      accessible.must_include @trip_claim_4_1
      accessible.wont_include @trip_claim_4_2
      accessible.wont_include @trip_claim_6_1
    end
    
    it "can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @provider_admin.cannot?(:create, TripClaim.new)
      assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
      assert @provider_admin.can?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
      assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
      assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
    end
    
    it "can read trip claims belonging to their own provider or belonging to trip_tickets that belong to their own provider" do
      assert @provider_admin.can?(:read, @trip_claim_1_1)
      assert @provider_admin.can?(:read, @trip_claim_2_1)
      assert @provider_admin.can?(:read, @trip_claim_4_1)    
      assert @provider_admin.cannot?(:read, @trip_claim_4_2)
      assert @provider_admin.cannot?(:read, @trip_claim_6_1)
    end
    
    it "can update trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @provider_admin.cannot?(:update, @trip_claim_1_1)
      assert @provider_admin.cannot?(:update, @trip_claim_2_1)
      assert @provider_admin.can?(:update, @trip_claim_4_1)
      assert @provider_admin.cannot?(:update, @trip_claim_4_2)
      assert @provider_admin.cannot?(:update, @trip_claim_6_1)
    end
    
    it "cannot destroy any trip claims" do
      assert @provider_admin.cannot?(:destroy, @trip_claim_1_1)
      assert @provider_admin.cannot?(:destroy, @trip_claim_2_1)
      assert @provider_admin.cannot?(:destroy, @trip_claim_4_1)
      assert @provider_admin.cannot?(:destroy, @trip_claim_4_2)
      assert @provider_admin.cannot?(:destroy, @trip_claim_6_1)
    end

    it "can rescind trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @provider_admin.cannot?(:rescind, @trip_claim_1_1)
      assert @provider_admin.cannot?(:rescind, @trip_claim_2_1)
      assert @provider_admin.can?(:rescind, @trip_claim_4_1)
      assert @provider_admin.cannot?(:rescind, @trip_claim_4_2)
      assert @provider_admin.cannot?(:rescind, @trip_claim_6_1)
    end
    
    it "can approve trip claims belonging to trip tickets that belong to their own provider" do
      assert @provider_admin.can?(:approve, @trip_claim_1_1)
      assert @provider_admin.can?(:approve, @trip_claim_2_1)    
      assert @provider_admin.cannot?(:approve, @trip_claim_4_1)
      assert @provider_admin.cannot?(:approve, @trip_claim_4_2)
      assert @provider_admin.cannot?(:approve, @trip_claim_6_1)
    end
    
    it "can decline trip claims belonging to trip tickets that belong to their own provider" do
      assert @provider_admin.can?(:decline, @trip_claim_1_1)
      assert @provider_admin.can?(:decline, @trip_claim_2_1)
      assert @provider_admin.cannot?(:decline, @trip_claim_4_1)
      assert @provider_admin.cannot?(:decline, @trip_claim_4_2)
      assert @provider_admin.cannot?(:decline, @trip_claim_6_1)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip claims that belong to their own provider or belong to trip tickets that belong to their own provider" do
      accessible = TripClaim.accessible_by(@scheduler)
      accessible.must_include @trip_claim_1_1
      accessible.must_include @trip_claim_2_1
      accessible.must_include @trip_claim_4_1
      accessible.wont_include @trip_claim_4_2
      accessible.wont_include @trip_claim_6_1
    end
    
    it "can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @scheduler.cannot?(:create, TripClaim.new)
      assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
      assert @scheduler.can?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
      assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
      assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
    end
    
    it "can read trip claims belonging to their own provider or belonging to trip_tickets that belong to their own provider" do
      assert @scheduler.can?(:read, @trip_claim_1_1)
      assert @scheduler.can?(:read, @trip_claim_2_1)
      assert @scheduler.can?(:read, @trip_claim_4_1)    
      assert @scheduler.cannot?(:read, @trip_claim_4_2)
      assert @scheduler.cannot?(:read, @trip_claim_6_1)
    end
    
    it "can update trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @scheduler.cannot?(:update, @trip_claim_1_1)
      assert @scheduler.cannot?(:update, @trip_claim_2_1)
      assert @scheduler.can?(:update, @trip_claim_4_1)
      assert @scheduler.cannot?(:update, @trip_claim_4_2)
      assert @scheduler.cannot?(:update, @trip_claim_6_1)
    end
    
    it "cannot destroy any trip claims" do
      assert @scheduler.cannot?(:destroy, @trip_claim_1_1)
      assert @scheduler.cannot?(:destroy, @trip_claim_2_1)
      assert @scheduler.cannot?(:destroy, @trip_claim_4_1)
      assert @scheduler.cannot?(:destroy, @trip_claim_4_2)
      assert @scheduler.cannot?(:destroy, @trip_claim_6_1)
    end

    it "can rescind trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
      assert @scheduler.cannot?(:rescind, @trip_claim_1_1)
      assert @scheduler.cannot?(:rescind, @trip_claim_2_1)
      assert @scheduler.can?(:rescind, @trip_claim_4_1)
      assert @scheduler.cannot?(:rescind, @trip_claim_4_2)
      assert @scheduler.cannot?(:rescind, @trip_claim_6_1)
    end
    
    it "can approve trip claims belonging to trip tickets that belong to their own provider" do
      assert @scheduler.can?(:approve, @trip_claim_1_1)
      assert @scheduler.can?(:approve, @trip_claim_2_1)    
      assert @scheduler.cannot?(:approve, @trip_claim_4_1)
      assert @scheduler.cannot?(:approve, @trip_claim_4_2)
      assert @scheduler.cannot?(:approve, @trip_claim_6_1)
    end
    
    it "can decline trip claims belonging to trip tickets that belong to their own provider" do
      assert @scheduler.can?(:decline, @trip_claim_1_1)
      assert @scheduler.can?(:decline, @trip_claim_2_1)
      assert @scheduler.cannot?(:decline, @trip_claim_4_1)
      assert @scheduler.cannot?(:decline, @trip_claim_4_2)
      assert @scheduler.cannot?(:decline, @trip_claim_6_1)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip claims that belong to their own provider or belong to trip tickets that belong to their own provider" do
      accessible = TripClaim.accessible_by(@dispatcher)
      accessible.must_include @trip_claim_1_1
      accessible.must_include @trip_claim_2_1
      accessible.must_include @trip_claim_4_1
      accessible.wont_include @trip_claim_4_2
      accessible.wont_include @trip_claim_6_1
    end
    
    it "cannot create trip claims regardless of provider" do
      assert @dispatcher.cannot?(:create, TripClaim.new)
      assert @dispatcher.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
      assert @dispatcher.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
      assert @dispatcher.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
      assert @dispatcher.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      assert @dispatcher.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
    end
    
    it "can read trip claims belonging to their own provider or belonging to trip_tickets that belong to their own provider" do
      assert @dispatcher.can?(:read, @trip_claim_1_1)
      assert @dispatcher.can?(:read, @trip_claim_2_1)
      assert @dispatcher.can?(:read, @trip_claim_4_1)    
      assert @dispatcher.cannot?(:read, @trip_claim_4_2)
      assert @dispatcher.cannot?(:read, @trip_claim_6_1)
    end
    
    it "cannot update trip claims regardless of provider" do
      assert @dispatcher.cannot?(:update, @trip_claim_1_1)
      assert @dispatcher.cannot?(:update, @trip_claim_2_1)
      assert @dispatcher.cannot?(:update, @trip_claim_4_1)
      assert @dispatcher.cannot?(:update, @trip_claim_4_2)
      assert @dispatcher.cannot?(:update, @trip_claim_6_1)
    end
    
    it "cannot destroy any trip claims" do
      assert @dispatcher.cannot?(:destroy, @trip_claim_1_1)
      assert @dispatcher.cannot?(:destroy, @trip_claim_2_1)
      assert @dispatcher.cannot?(:destroy, @trip_claim_4_1)
      assert @dispatcher.cannot?(:destroy, @trip_claim_4_2)
      assert @dispatcher.cannot?(:destroy, @trip_claim_6_1)
    end

    it "cannot rescind trip claims regardless of provider" do
      assert @dispatcher.cannot?(:rescind, @trip_claim_1_1)
      assert @dispatcher.cannot?(:rescind, @trip_claim_2_1)
      assert @dispatcher.cannot?(:rescind, @trip_claim_4_1)
      assert @dispatcher.cannot?(:rescind, @trip_claim_4_2)
      assert @dispatcher.cannot?(:rescind, @trip_claim_6_1)
    end
    
    it "cannot approve trip claims regardless of provider" do
      assert @dispatcher.cannot?(:approve, @trip_claim_1_1)
      assert @dispatcher.cannot?(:approve, @trip_claim_2_1)    
      assert @dispatcher.cannot?(:approve, @trip_claim_4_1)
      assert @dispatcher.cannot?(:approve, @trip_claim_4_2)
      assert @dispatcher.cannot?(:approve, @trip_claim_6_1)
    end
    
    it "cannot decline trip claims regardless of provider" do
      assert @dispatcher.cannot?(:decline, @trip_claim_1_1)
      assert @dispatcher.cannot?(:decline, @trip_claim_2_1)
      assert @dispatcher.cannot?(:decline, @trip_claim_4_1)
      assert @dispatcher.cannot?(:decline, @trip_claim_4_2)
      assert @dispatcher.cannot?(:decline, @trip_claim_6_1)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to find trip claims that belong to their own provider or belong to trip tickets that belong to their own provider" do
      accessible = TripClaim.accessible_by(@read_only)
      accessible.must_include @trip_claim_1_1
      accessible.must_include @trip_claim_2_1
      accessible.must_include @trip_claim_4_1
      accessible.wont_include @trip_claim_4_2
      accessible.wont_include @trip_claim_6_1
    end
    
    it "cannot create trip claims regardless of provider" do
      assert @read_only.cannot?(:create, TripClaim.new)
      assert @read_only.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
      assert @read_only.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
      assert @read_only.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
      assert @read_only.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      assert @read_only.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
    end
    
    it "can read trip claims belonging to their own provider or belonging to trip_tickets that belong to their own provider" do
      assert @read_only.can?(:read, @trip_claim_1_1)
      assert @read_only.can?(:read, @trip_claim_2_1)
      assert @read_only.can?(:read, @trip_claim_4_1)    
      assert @read_only.cannot?(:read, @trip_claim_4_2)
      assert @read_only.cannot?(:read, @trip_claim_6_1)
    end
    
    it "cannot update trip claims regardless of provider" do
      assert @read_only.cannot?(:update, @trip_claim_1_1)
      assert @read_only.cannot?(:update, @trip_claim_2_1)
      assert @read_only.cannot?(:update, @trip_claim_4_1)
      assert @read_only.cannot?(:update, @trip_claim_4_2)
      assert @read_only.cannot?(:update, @trip_claim_6_1)
    end
    
    it "cannot destroy any trip claims" do
      assert @read_only.cannot?(:destroy, @trip_claim_1_1)
      assert @read_only.cannot?(:destroy, @trip_claim_2_1)
      assert @read_only.cannot?(:destroy, @trip_claim_4_1)
      assert @read_only.cannot?(:destroy, @trip_claim_4_2)
      assert @read_only.cannot?(:destroy, @trip_claim_6_1)
    end

    it "cannot rescind trip claims regardless of provider" do
      assert @read_only.cannot?(:rescind, @trip_claim_1_1)
      assert @read_only.cannot?(:rescind, @trip_claim_2_1)
      assert @read_only.cannot?(:rescind, @trip_claim_4_1)
      assert @read_only.cannot?(:rescind, @trip_claim_4_2)
      assert @read_only.cannot?(:rescind, @trip_claim_6_1)
    end
    
    it "cannot approve trip claims regardless of provider" do
      assert @read_only.cannot?(:approve, @trip_claim_1_1)
      assert @read_only.cannot?(:approve, @trip_claim_2_1)    
      assert @read_only.cannot?(:approve, @trip_claim_4_1)
      assert @read_only.cannot?(:approve, @trip_claim_4_2)
      assert @read_only.cannot?(:approve, @trip_claim_6_1)
    end
    
    it "cannot decline trip claims regardless of provider" do
      assert @read_only.cannot?(:decline, @trip_claim_1_1)
      assert @read_only.cannot?(:decline, @trip_claim_2_1)
      assert @read_only.cannot?(:decline, @trip_claim_4_1)
      assert @read_only.cannot?(:decline, @trip_claim_4_2)
      assert @read_only.cannot?(:decline, @trip_claim_6_1)
    end
  end  
end
