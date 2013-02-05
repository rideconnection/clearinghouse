require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  setup do
    @roles = {
      :site_admin     => FactoryGirl.create(:role, :name => "site_admin"),
      :provider_admin => FactoryGirl.create(:role, :name => "provider_admin"),
      :scheduler      => FactoryGirl.create(:role, :name => "scheduler"),
      :dispatcher     => FactoryGirl.create(:role, :name => "dispatcher"),
      :csr            => FactoryGirl.create(:role, :name => "csr")
    }

    @provider_1 = FactoryGirl.create(:provider)
    @provider_2 = FactoryGirl.create(:provider)
    @provider_3 = FactoryGirl.create(:provider)

    @provider_relationship_1 = ProviderRelationship.create!(:requesting_provider => @provider_1, :cooperating_provider => @provider_2)
    @provider_relationship_2 = ProviderRelationship.create!(:requesting_provider => @provider_2, :cooperating_provider => @provider_3)
    @provider_relationship_3 = ProviderRelationship.create!(:requesting_provider => @provider_3, :cooperating_provider => @provider_1)
    @provider_relationship_1.approve!
    @provider_relationship_2.approve!

    # Open trip ticket from provider_1
    @trip_ticket_1  = FactoryGirl.create(:trip_ticket, :originator => @provider_1)
    @trip_claim_1_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_1, :claimant => @provider_2, :status => TripClaim::STATUS[:pending])
    @trip_ticket_comment_1_1 = FactoryGirl.create(:trip_ticket_comment, :trip_ticket => @trip_ticket_1)

    # Claimed trip ticket from provider_1
    @trip_ticket_2  = FactoryGirl.create(:trip_ticket, :originator => @provider_1)
    @trip_claim_2_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_2, :claimant => @provider_2, :status => TripClaim::STATUS[:approved])

    # Open trip ticket from provider_2, no claims
    @trip_ticket_3  = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
    @trip_ticket_comment_3_1 = FactoryGirl.create(:trip_ticket_comment, :trip_ticket => @trip_ticket_3)

    # Claimed trip ticket from provider_2
    @trip_ticket_4  = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
    @trip_claim_4_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_4, :claimant => @provider_1, :status => TripClaim::STATUS[:pending])
    @trip_claim_4_2 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_4, :claimant => @provider_3, :status => TripClaim::STATUS[:approved])

    # Open trip ticket from provider_3, no claims
    @trip_ticket_5  = FactoryGirl.create(:trip_ticket, :originator => @provider_3)
    @trip_ticket_comment_5_1 = FactoryGirl.create(:trip_ticket_comment, :trip_ticket => @trip_ticket_5)

    # Claimed trip ticket from provider_3
    @trip_ticket_6  = FactoryGirl.create(:trip_ticket, :originator => @provider_3)
    @trip_claim_6_1 = FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket_6, :claimant => @provider_2, :status => TripClaim::STATUS[:approved])

    @user_1 = FactoryGirl.create(:user, :provider => @provider_1)
    @user_2 = FactoryGirl.create(:user, :provider => @provider_2)
    @user_3 = FactoryGirl.create(:user, :provider => @provider_1)

    @service_1 = FactoryGirl.create(:service, :provider => @provider_1)
    @service_2 = FactoryGirl.create(:service, :provider => @provider_2)
    @service_3 = FactoryGirl.create(:service, :provider => @provider_3)
  end

  teardown do
    Role.destroy_all
    Provider.destroy_all
    ProviderRelationship.destroy_all
    TripTicket.destroy_all
    TripClaim.destroy_all
    User.destroy_all
    Service.destroy_all
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user)
      @current_user.roles << @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end
  
    describe "trip tickets" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = TripTicket.accessible_by(@site_admin)
        accessible.must_include @trip_ticket_1
        accessible.must_include @trip_ticket_2
        accessible.must_include @trip_ticket_3
        accessible.must_include @trip_ticket_4
        accessible.must_include @trip_ticket_5
        accessible.must_include @trip_ticket_6
      end
  
      it "allows :create access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:create, TripTicket.new)
        assert @site_admin.can?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))
        assert @site_admin.can?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      end
  
      it "allows :read access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:read, @trip_ticket_1)
        assert @site_admin.can?(:read, @trip_ticket_2)
        assert @site_admin.can?(:read, @trip_ticket_3)
        assert @site_admin.can?(:read, @trip_ticket_4)
        assert @site_admin.can?(:read, @trip_ticket_5)
        assert @site_admin.can?(:read, @trip_ticket_6)
      end
  
      it "allows :update access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:update, @trip_ticket_1)
        assert @site_admin.can?(:update, @trip_ticket_2)
        assert @site_admin.can?(:update, @trip_ticket_3)
        assert @site_admin.can?(:update, @trip_ticket_4)
        assert @site_admin.can?(:update, @trip_ticket_5)
        assert @site_admin.can?(:update, @trip_ticket_6)
      end
  
      it "allows :destroy access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:destroy, @trip_ticket_1)
        assert @site_admin.can?(:destroy, @trip_ticket_2)
        assert @site_admin.can?(:destroy, @trip_ticket_3)
        assert @site_admin.can?(:destroy, @trip_ticket_4)
        assert @site_admin.can?(:destroy, @trip_ticket_5)
        assert @site_admin.can?(:destroy, @trip_ticket_6)
      end
    end
  
    describe "trip claims" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = TripClaim.accessible_by(@site_admin)
        accessible.must_include @trip_claim_1_1
        accessible.must_include @trip_claim_2_1
        accessible.must_include @trip_claim_4_1
        accessible.must_include @trip_claim_4_2
        accessible.must_include @trip_claim_6_1
      end
  
      it "allows :create access to all regardless of trip_ticket originating provider or trip_claim claimant provider" do
        assert @site_admin.can?(:create, TripClaim.new)
        assert @site_admin.can?(:create, TripClaim.new(:trip_ticket_id => @trip_ticket_1.id))
        assert @site_admin.can?(:create, TripClaim.new(:trip_ticket_id => @trip_ticket_3.id))
      end
  
      it "allows :read access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:read, @trip_claim_1_1)
        assert @site_admin.can?(:read, @trip_claim_2_1)
        assert @site_admin.can?(:read, @trip_claim_4_1)
        assert @site_admin.can?(:read, @trip_claim_4_2)
        assert @site_admin.can?(:read, @trip_claim_6_1)
      end
  
      it "allows :update access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:update, @trip_claim_1_1)
        assert @site_admin.can?(:update, @trip_claim_2_1)
        assert @site_admin.can?(:update, @trip_claim_4_1)
        assert @site_admin.can?(:update, @trip_claim_4_2)
        assert @site_admin.can?(:update, @trip_claim_6_1)
      end
  
      it "allows :destroy access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:destroy, @trip_claim_1_1)
        assert @site_admin.can?(:destroy, @trip_claim_2_1)
        assert @site_admin.can?(:destroy, @trip_claim_4_1)
        assert @site_admin.can?(:destroy, @trip_claim_4_2)
        assert @site_admin.can?(:destroy, @trip_claim_6_1)
      end
  
      it "allows :approve access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:approve, @trip_claim_1_1)
        assert @site_admin.can?(:approve, @trip_claim_2_1)
        assert @site_admin.can?(:approve, @trip_claim_4_1)
        assert @site_admin.can?(:approve, @trip_claim_4_2)
        assert @site_admin.can?(:approve, @trip_claim_6_1)
      end
  
      it "allows :decline access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:decline, @trip_claim_1_1)
        assert @site_admin.can?(:decline, @trip_claim_2_1)
        assert @site_admin.can?(:decline, @trip_claim_4_1)
        assert @site_admin.can?(:decline, @trip_claim_4_2)
        assert @site_admin.can?(:decline, @trip_claim_6_1)
      end
    end
  
    describe "trip ticket comments" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = TripTicketComment.accessible_by(@site_admin)
        accessible.must_include @trip_ticket_comment_1_1
        accessible.must_include @trip_ticket_comment_3_1
        accessible.must_include @trip_ticket_comment_5_1
      end
  
      it "allows :create access to all regardless of trip_ticket originating provider or provider relationships" do
        assert @site_admin.can?(:create, TripTicketComment.new)
        assert @site_admin.can?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_1.id))
        assert @site_admin.can?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_3.id))
        assert @site_admin.can?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_5.id))
      end
  
      it "allows :read access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:read, @trip_ticket_comment_1_1)
        assert @site_admin.can?(:read, @trip_ticket_comment_3_1)
        assert @site_admin.can?(:read, @trip_ticket_comment_5_1)
      end
  
      it "allows :update access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:update, @trip_ticket_comment_1_1)
        assert @site_admin.can?(:update, @trip_ticket_comment_3_1)
        assert @site_admin.can?(:update, @trip_ticket_comment_5_1)
      end
  
      it "allows :destroy access to all regardless of originating provider or provider relationships" do
        assert @site_admin.can?(:destroy, @trip_ticket_comment_1_1)
        assert @site_admin.can?(:destroy, @trip_ticket_comment_3_1)
        assert @site_admin.can?(:destroy, @trip_ticket_comment_5_1)
      end
    end
  
    describe "current user" do
      it "can read its own user record" do
        assert @site_admin.can?(:read, @current_user)
      end
    
      it "can update its own user record" do
        assert @site_admin.can?(:update, @current_user)
      end
    
      it "cannot destroy its own user record" do
        assert @site_admin.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @site_admin.cannot?(:deactivate, @current_user)
      end
    end    
  
    describe "users" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = User.accessible_by(@site_admin)
        accessible.must_include @current_user
        accessible.must_include @user_1
        accessible.must_include @user_2
        accessible.must_include @user_3
      end
  
      it "allows :create access to all regardless of the user's provider" do
        assert @site_admin.can?(:create, User.new)
      end
  
      it "allows :read access to all regardless of the user's provider" do
        assert @site_admin.can?(:read, @user_1)
        assert @site_admin.can?(:read, @user_2)
        assert @site_admin.can?(:read, @user_3)
      end
  
      it "allows :update access to all regardless of the user's provider" do
        assert @site_admin.can?(:update, @user_1)
        assert @site_admin.can?(:update, @user_2)
        assert @site_admin.can?(:update, @user_3)
      end
  
      it "allows :destroy access to all regardless of the user's provider" do
        assert @site_admin.can?(:destroy, @user_1)
        assert @site_admin.can?(:destroy, @user_2)
        assert @site_admin.can?(:destroy, @user_3)
      end
  
      it "allows :activate access to all regardless of the user's provider" do
        assert @site_admin.can?(:activate, @user_1)
        assert @site_admin.can?(:activate, @user_2)
        assert @site_admin.can?(:activate, @user_3)
      end
  
      it "allows :deactivate access to all regardless of the user's provider" do
        assert @site_admin.can?(:deactivate, @user_1)
        assert @site_admin.can?(:deactivate, @user_2)
        assert @site_admin.can?(:deactivate, @user_3)
      end
  
      it "allows :set_provider_role access to all regardless of the user's provider" do
        assert @site_admin.can?(:set_provider_role, @user_1)
        assert @site_admin.can?(:set_provider_role, @user_2)
        assert @site_admin.can?(:set_provider_role, @user_3)
      end
    end
  
    describe "providers" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = Provider.accessible_by(@site_admin)
        accessible.must_include @provider_1
        accessible.must_include @provider_2
        accessible.must_include @provider_3
      end
  
      it "allows :create access to all regardless of user's provider_id" do
        assert @site_admin.can?(:create, Provider.new)
      end
  
      it "allows :read access to all regardless of user's provider_id" do
        assert @site_admin.can?(:read, @provider_1)
        assert @site_admin.can?(:read, @provider_2)
        assert @site_admin.can?(:read, @provider_3)
      end
  
      it "allows :update access to all regardless of user's provider_id" do
        assert @site_admin.can?(:update, @provider_1)
        assert @site_admin.can?(:update, @provider_2)
        assert @site_admin.can?(:update, @provider_3)
      end
  
      it "allows :destroy access to all regardless of user's provider_id" do
        assert @site_admin.can?(:destroy, @provider_1)
        assert @site_admin.can?(:destroy, @provider_2)
        assert @site_admin.can?(:destroy, @provider_3)
      end
    end
  
    describe "provider relationships" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = ProviderRelationship.accessible_by(@site_admin)
        accessible.must_include @provider_relationship_1
        accessible.must_include @provider_relationship_2
        accessible.must_include @provider_relationship_3
      end
  
      it "allows :create access to all regardless of cooperating_provider_id or requesting_provider_id" do
        assert @site_admin.can?(:create, ProviderRelationship.new)
      end
  
      it "allows :read access to all regardless of cooperating_provider_id or requesting_provider_id" do
        assert @site_admin.can?(:read, @provider_relationship_1)
        assert @site_admin.can?(:read, @provider_relationship_2)
        assert @site_admin.can?(:read, @provider_relationship_3)
      end
  
      it "allows :update access to all regardless of cooperating_provider_id or requesting_provider_id" do
        assert @site_admin.can?(:update, @provider_relationship_1)
        assert @site_admin.can?(:update, @provider_relationship_2)
        assert @site_admin.can?(:update, @provider_relationship_3)
      end
  
      it "allows :destroy access to all regardless of cooperating_provider_id or requesting_provider_id" do
        assert @site_admin.can?(:destroy, @provider_relationship_1)
        assert @site_admin.can?(:destroy, @provider_relationship_2)
        assert @site_admin.can?(:destroy, @provider_relationship_3)
      end
  
      it "allows :activate access to all regardless of cooperating_provider_id or requesting_provider_id" do
        assert @site_admin.can?(:activate, @provider_relationship_1)
        assert @site_admin.can?(:activate, @provider_relationship_2)
        assert @site_admin.can?(:activate, @provider_relationship_3)
      end
    end
  
    describe "services" do
      it "can use accessible_by to load a list of accessible resources" do
        accessible = Service.accessible_by(@site_admin)
        accessible.must_include @service_1
        accessible.must_include @service_2
        accessible.must_include @service_3
      end
  
      it "allows :create access to all regardless of user's provider_id" do
        assert @site_admin.can?(:create, Service.new)
      end
  
      it "allows :read access to all regardless of user's provider_id" do
        assert @site_admin.can?(:read, @service_1)
        assert @site_admin.can?(:read, @service_2)
        assert @site_admin.can?(:read, @service_3)
      end
  
      it "allows :update access to all regardless of user's provider_id" do
        assert @site_admin.can?(:update, @service_1)
        assert @site_admin.can?(:update, @service_2)
        assert @site_admin.can?(:update, @service_3)
      end
  
      it "allows :destroy access to all regardless of user's provider_id" do
        assert @site_admin.can?(:destroy, @service_1)
        assert @site_admin.can?(:destroy, @service_2)
        assert @site_admin.can?(:destroy, @service_3)
      end
    end
  end
  
  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.roles << @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end
  
    teardown do; end
  
    describe "trip tickets" do
      it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
        accessible = TripTicket.accessible_by(@provider_admin)
        accessible.must_include @trip_ticket_1
        accessible.must_include @trip_ticket_2
        accessible.must_include @trip_ticket_3
        accessible.must_include @trip_ticket_4
    
        accessible.wont_include @trip_ticket_5
        accessible.wont_include @trip_ticket_6
      end
    
      it "can create trip tickets belonging to their own provider" do
        assert @provider_admin.can?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))
    
        assert @provider_admin.cannot?(:create, TripTicket.new)
        assert @provider_admin.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      end
    
      it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
        assert @provider_admin.can?(:read, @trip_ticket_1)
        assert @provider_admin.can?(:read, @trip_ticket_2)
        assert @provider_admin.can?(:read, @trip_ticket_3)
        assert @provider_admin.can?(:read, @trip_ticket_4)
    
        assert @provider_admin.cannot?(:read, @trip_ticket_5)
        assert @provider_admin.cannot?(:read, @trip_ticket_6)
      end
    
      it "can update trip tickets belonging to their own provider" do
        assert @provider_admin.can?(:update, @trip_ticket_1)
        assert @provider_admin.can?(:update, @trip_ticket_2)
    
        assert @provider_admin.cannot?(:update, @trip_ticket_3)
        assert @provider_admin.cannot?(:update, @trip_ticket_4)
        assert @provider_admin.cannot?(:update, @trip_ticket_5)
        assert @provider_admin.cannot?(:update, @trip_ticket_6)
      end
    
      it "can destroy trip tickets belonging to their own provider" do
        assert @provider_admin.can?(:destroy, @trip_ticket_1)
        assert @provider_admin.can?(:destroy, @trip_ticket_2)
    
        assert @provider_admin.cannot?(:destroy, @trip_ticket_3)
        assert @provider_admin.cannot?(:destroy, @trip_ticket_4)
        assert @provider_admin.cannot?(:destroy, @trip_ticket_5)
        assert @provider_admin.cannot?(:destroy, @trip_ticket_6)
      end
    end
    
    describe "trip claims" do
      it "can use accessible_by to find trip claims belonging to their own provider or associated with trip_tickets that belong to their own provider" do
        accessible = TripClaim.accessible_by(@provider_admin)
        accessible.must_include @trip_claim_1_1
        accessible.must_include @trip_claim_2_1
        accessible.must_include @trip_claim_4_1
    
        accessible.wont_include @trip_claim_4_2
        accessible.wont_include @trip_claim_6_1
      end
    
      it "can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
        assert @provider_admin.can?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
    
        assert @provider_admin.cannot?(:create, TripClaim.new)
        assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
        assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
        assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
        assert @provider_admin.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      end
    
      it "can read trip claims belonging to their own provider or associated with trip_tickets that belong to their own provider" do
        assert @provider_admin.can?(:read, @trip_claim_1_1)
        assert @provider_admin.can?(:read, @trip_claim_2_1)
        assert @provider_admin.can?(:read, @trip_claim_4_1)
    
        assert @provider_admin.cannot?(:read, @trip_claim_4_2)
        assert @provider_admin.cannot?(:read, @trip_claim_6_1)
      end
    
      it "can update trip claims belonging to their own provider" do
        assert @provider_admin.can?(:update, @trip_claim_4_1)
    
        assert @provider_admin.cannot?(:update, @trip_claim_1_1)
        assert @provider_admin.cannot?(:update, @trip_claim_2_1)
        assert @provider_admin.cannot?(:update, @trip_claim_4_2)
        assert @provider_admin.cannot?(:update, @trip_claim_6_1)
      end
    
      it "can destroy trip claims belonging to their own provider" do
        assert @provider_admin.can?(:destroy, @trip_claim_4_1)
    
        assert @provider_admin.cannot?(:destroy, @trip_claim_1_1)
        assert @provider_admin.cannot?(:destroy, @trip_claim_2_1)
        assert @provider_admin.cannot?(:destroy, @trip_claim_4_2)
        assert @provider_admin.cannot?(:destroy, @trip_claim_6_1)
      end
    
      it "can approve trip claims associated with trip tickets that belong to their own provider, but not trip claims belonging to their own provider" do
        assert @provider_admin.can?(:approve, @trip_claim_1_1)
        assert @provider_admin.can?(:approve, @trip_claim_2_1)
    
        assert @provider_admin.cannot?(:approve, @trip_claim_4_1)
        assert @provider_admin.cannot?(:approve, @trip_claim_4_2)
        assert @provider_admin.cannot?(:approve, @trip_claim_6_1)
      end
    
      it "can decline trip claims associated with trip tickets that belong to their own provider, but not trip claims belonging to their own provider" do
        assert @provider_admin.can?(:decline, @trip_claim_1_1)
        assert @provider_admin.can?(:decline, @trip_claim_2_1)
    
        assert @provider_admin.cannot?(:decline, @trip_claim_4_1)
        assert @provider_admin.cannot?(:decline, @trip_claim_4_2)
        assert @provider_admin.cannot?(:decline, @trip_claim_6_1)
      end
    end
    
    describe "trip ticket comments" do
      it "can use accessible_by to find trip ticket comments belonging to trip tickets from their own provider" do
        accessible = TripTicketComment.accessible_by(@provider_admin)
        accessible.must_include @trip_ticket_comment_1_1

        accessible.wont_include @trip_ticket_comment_3_1
        accessible.wont_include @trip_ticket_comment_5_1
      end
    
      it "can create trip ticket comments on trip tickets belonging to their own provider" do
        assert @provider_admin.can?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_1.id))
    
        assert @provider_admin.cannot?(:create, TripTicketComment.new)
        assert @provider_admin.cannot?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_3.id))
        assert @provider_admin.cannot?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_5.id))
      end
    
      it "can read trip ticket comments belonging to trip_tickets from their own provider" do
        assert @provider_admin.can?(:read, @trip_ticket_comment_1_1)
    
        assert @provider_admin.cannot?(:read, @trip_ticket_comment_3_1)
        assert @provider_admin.cannot?(:read, @trip_ticket_comment_5_1)
      end
    
      it "can update trip ticket comments belonging to trip_tickets from their own provider" do
        assert @provider_admin.can?(:update, @trip_ticket_comment_1_1)
    
        assert @provider_admin.cannot?(:update, @trip_ticket_comment_3_1)
        assert @provider_admin.cannot?(:update, @trip_ticket_comment_5_1)
      end
    
      it "can destroy trip ticket comments belonging to trip_tickets from their own provider" do
        assert @provider_admin.can?(:destroy, @trip_ticket_comment_1_1)
    
        assert @provider_admin.cannot?(:destroy, @trip_ticket_comment_3_1)
        assert @provider_admin.cannot?(:destroy, @trip_ticket_comment_5_1)
      end
    end
    
    describe "current user" do
      it "can read its own user record" do
        assert @provider_admin.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @provider_admin.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @provider_admin.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @provider_admin.cannot?(:deactivate, @current_user)
      end
    end    
    
    describe "users" do
      it "can use accessible_by to find users belonging to their own provider" do
        accessible = User.accessible_by(@provider_admin)
        accessible.must_include @current_user
        accessible.must_include @user_1
        accessible.must_include @user_3
    
        accessible.wont_include @user_2
      end
    
      it "can create users belonging to their own provider" do
        assert @provider_admin.can?(:create, User.new(:provider_id => @provider_1.id))
    
        assert @provider_admin.cannot?(:create, User.new)
        assert @provider_admin.cannot?(:create, User.new(:provider_id => @provider_2.id))
        assert @provider_admin.cannot?(:create, User.new(:provider_id => @provider_3.id))
      end
    
      it "can read other users belonging to their own provider" do
        assert @provider_admin.can?(:read, @user_1)
        assert @provider_admin.can?(:read, @user_3)
    
        assert @provider_admin.cannot?(:read, @user_2)
      end
    
      it "can update users belonging to their own provider" do
        assert @provider_admin.can?(:update, @user_1)
        assert @provider_admin.can?(:update, @user_3)
    
        assert @provider_admin.cannot?(:update, @user_2)
      end
    
      it "cannot destroy any users regardless of provider" do
        assert @provider_admin.cannot?(:destroy, @user_1)
        assert @provider_admin.cannot?(:destroy, @user_2)
        assert @provider_admin.cannot?(:destroy, @user_3)
      end
    
      it "can activate users belonging to their own provider" do
        assert @provider_admin.can?(:activate, @user_1)
        assert @provider_admin.can?(:activate, @user_3)
    
        assert @provider_admin.cannot?(:activate, @user_2)
      end
      
      it "can deactivate users belonging to their own provider" do
        assert @provider_admin.can?(:deactivate, @user_1)
        assert @provider_admin.can?(:deactivate, @user_3)
    
        assert @provider_admin.cannot?(:deactivate, @user_2)
      end
      
      it "can set the role users belonging to their own provider" do
        assert @provider_admin.can?(:set_provider_role, @user_1)
        assert @provider_admin.can?(:set_provider_role, @user_3)
    
        assert @provider_admin.cannot?(:set_provider_role, @user_2)
      end
    end
    
    describe "providers" do
      it "can use accessible_by to find their own provider and providers they have an approved relationship with" do
        accessible = Provider.accessible_by(@provider_admin)
        accessible.must_include @provider_1
        accessible.must_include @provider_2
    
        accessible.wont_include @provider_3
      end
    
      it "cannot create providers" do
        assert @provider_admin.cannot?(:create, Provider.new)
        assert @provider_admin.cannot?(:create, Provider.new(:id => @provider_1.id))
      end
      
      it "can read their own provider or providers they have an approved relationship with" do
        assert @provider_admin.can?(:read, @provider_1)
        assert @provider_admin.can?(:read, @provider_2)
    
        assert @provider_admin.cannot?(:read, @provider_3)
      end
      
      it "can update their own provider" do
        assert @provider_admin.can?(:update, @provider_1)
    
        assert @provider_admin.cannot?(:update, @provider_2)
        assert @provider_admin.cannot?(:update, @provider_3)
      end
      
      it "cannot destroy their own provider or any other provider" do
        assert @provider_admin.cannot?(:destroy, @provider_1)
        assert @provider_admin.cannot?(:destroy, @provider_2)
        assert @provider_admin.cannot?(:destroy, @provider_3)
      end
      
      it "can view the keys of their own provider" do
        assert @provider_admin.can?(:keys, @provider_1)
    
        assert @provider_admin.cannot?(:keys, @provider_2)
        assert @provider_admin.cannot?(:keys, @provider_3)
      end
      
      it "can reset the keys of their own provider" do
        assert @provider_admin.can?(:reset_keys, @provider_1)
    
        assert @provider_admin.cannot?(:reset_keys, @provider_2)
        assert @provider_admin.cannot?(:reset_keys, @provider_3)
      end
    end
    
    describe "provider relationships" do
      it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
        accessible = ProviderRelationship.accessible_by(@provider_admin)
        accessible.must_include @provider_relationship_1
        accessible.must_include @provider_relationship_3
    
        accessible.wont_include @provider_relationship_2
      end
    
      it "can create provider relationships originating from their own provider" do
        assert @provider_admin.can?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))
    
        assert @provider_admin.cannot?(:create, ProviderRelationship.new)
        assert @provider_admin.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
        assert @provider_admin.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
      end
      
      it "can read provider relationships that their own provider belongs to" do
        assert @provider_admin.can?(:read, @provider_relationship_1)
        assert @provider_admin.can?(:read, @provider_relationship_3)
    
        assert @provider_admin.cannot?(:read, @provider_relationship_2)
      end
      
      it "can update provider relationships that their own provider belongs to" do
        assert @provider_admin.can?(:update, @provider_relationship_1)
        assert @provider_admin.can?(:update, @provider_relationship_3)
    
        assert @provider_admin.cannot?(:update, @provider_relationship_2)
      end
      
      it "can destroy provider relationships that their own provider belongs to" do
        assert @provider_admin.can?(:destroy, @provider_relationship_1)
        assert @provider_admin.can?(:destroy, @provider_relationship_3)
    
        assert @provider_admin.cannot?(:destroy, @provider_relationship_2)
      end
      
      it "can activate (aka approve) provider relationships sent to their own provider" do
        assert @provider_admin.can?(:activate, @provider_relationship_3)
        
        assert @provider_admin.cannot?(:activate, @provider_relationship_1)
        assert @provider_admin.cannot?(:activate, @provider_relationship_2)
      end
    end
    
    describe "services" do
      it "can use accessible_by to load a list of services belonging to their own provider" do
        accessible = Service.accessible_by(@provider_admin)
        accessible.must_include @service_1
  
        accessible.wont_include @service_2
        accessible.wont_include @service_3
      end
    
      it "can create services belonging to their own provider" do
        assert @provider_admin.can?(:create, Service.new(:provider_id => @provider_1.id))
        
        assert @provider_admin.cannot?(:create, Service.new)
        assert @provider_admin.cannot?(:create, Service.new(:provider_id => @provider_2.id))
        assert @provider_admin.cannot?(:create, Service.new(:provider_id => @provider_3.id))
      end
    
      it "can read services belonging to their own provider" do
        assert @provider_admin.can?(:read, @service_1)
  
        assert @provider_admin.cannot?(:read, @service_2)
        assert @provider_admin.cannot?(:read, @service_3)
      end
    
      it "can update services belonging to their own provider" do
        assert @provider_admin.can?(:update, @service_1)
  
        assert @provider_admin.cannot?(:update, @service_2)
        assert @provider_admin.cannot?(:update, @service_3)
      end
    
      it "cannot destroy services regardless of their provider" do
        assert @provider_admin.cannot?(:destroy, @service_1)
        assert @provider_admin.cannot?(:destroy, @service_2)
        assert @provider_admin.cannot?(:destroy, @service_3)
      end
    end
  end
  
  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.roles << @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    teardown do; end

    describe "trip tickets" do
      it "can use accessible_by to find trip tickets belonging to their own provider or providers they have an approved relationship with" do
        accessible = TripTicket.accessible_by(@scheduler)
        accessible.must_include @trip_ticket_1
        accessible.must_include @trip_ticket_2
        accessible.must_include @trip_ticket_3
        accessible.must_include @trip_ticket_4
    
        accessible.wont_include @trip_ticket_5
        accessible.wont_include @trip_ticket_6
      end
    
      it "cannot create trip tickets regardless of their provider" do
        assert @scheduler.cannot?(:create, TripTicket.new)
        assert @scheduler.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_1.id))
        assert @scheduler.cannot?(:create, TripTicket.new(:origin_provider_id => @provider_2.id))
      end
    
      it "can read trip tickets belonging to their own provider or providers they have an approved relationship with" do
        assert @scheduler.can?(:read, @trip_ticket_1)
        assert @scheduler.can?(:read, @trip_ticket_2)
        assert @scheduler.can?(:read, @trip_ticket_3)
        assert @scheduler.can?(:read, @trip_ticket_4)
    
        assert @scheduler.cannot?(:read, @trip_ticket_5)
        assert @scheduler.cannot?(:read, @trip_ticket_6)
      end
    
      it "cannot update trip tickets regardless of their provider" do
        assert @scheduler.cannot?(:update, @trip_ticket_1)
        assert @scheduler.cannot?(:update, @trip_ticket_2)
        assert @scheduler.cannot?(:update, @trip_ticket_3)
        assert @scheduler.cannot?(:update, @trip_ticket_4)
        assert @scheduler.cannot?(:update, @trip_ticket_5)
        assert @scheduler.cannot?(:update, @trip_ticket_6)
      end
    
      it "cannot destroy trip tickets regardless of their provider" do
        assert @scheduler.cannot?(:destroy, @trip_ticket_1)
        assert @scheduler.cannot?(:destroy, @trip_ticket_2)    
        assert @scheduler.cannot?(:destroy, @trip_ticket_3)
        assert @scheduler.cannot?(:destroy, @trip_ticket_4)
        assert @scheduler.cannot?(:destroy, @trip_ticket_5)
        assert @scheduler.cannot?(:destroy, @trip_ticket_6)
      end
    end
    
    describe "trip claims" do
      it "can use accessible_by to find trip claims belonging to their own provider" do
        accessible = TripClaim.accessible_by(@scheduler)
        accessible.must_include @trip_claim_1_1
        accessible.must_include @trip_claim_2_1
        accessible.must_include @trip_claim_4_1
    
        accessible.wont_include @trip_claim_4_2
        accessible.wont_include @trip_claim_6_1
      end
    
      it "can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets" do
        assert @scheduler.can?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_3.id))
    
        assert @scheduler.cannot?(:create, TripClaim.new)
        assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id))
        assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_1.id))
        assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_2.id, :trip_ticket_id => @trip_ticket_3.id))
        assert @scheduler.cannot?(:create, TripClaim.new(:claimant_provider_id => @provider_1.id, :trip_ticket_id => @trip_ticket_5.id))
      end
    
      it "can read trip claims belonging to their own provider or associated with trip_tickets that belong to their own provider" do
        assert @scheduler.can?(:read, @trip_claim_1_1)
        assert @scheduler.can?(:read, @trip_claim_2_1)
        assert @scheduler.can?(:read, @trip_claim_4_1)
    
        assert @scheduler.cannot?(:read, @trip_claim_4_2)
        assert @scheduler.cannot?(:read, @trip_claim_6_1)
      end
    
      it "can update trip claims belonging to their own provider" do
        assert @scheduler.can?(:update, @trip_claim_4_1)
    
        assert @scheduler.cannot?(:update, @trip_claim_1_1)
        assert @scheduler.cannot?(:update, @trip_claim_2_1)
        assert @scheduler.cannot?(:update, @trip_claim_4_2)
        assert @scheduler.cannot?(:update, @trip_claim_6_1)
      end
    
      it "can destroy trip claims belonging to their own provider" do
        assert @scheduler.can?(:destroy, @trip_claim_4_1)
    
        assert @scheduler.cannot?(:destroy, @trip_claim_1_1)
        assert @scheduler.cannot?(:destroy, @trip_claim_2_1)
        assert @scheduler.cannot?(:destroy, @trip_claim_4_2)
        assert @scheduler.cannot?(:destroy, @trip_claim_6_1)
      end
    
      it "cannot approve trip claims regardless of their provider" do
        assert @scheduler.cannot?(:approve, @trip_claim_1_1)
        assert @scheduler.cannot?(:approve, @trip_claim_2_1)
        assert @scheduler.cannot?(:approve, @trip_claim_4_1)
        assert @scheduler.cannot?(:approve, @trip_claim_4_2)
        assert @scheduler.cannot?(:approve, @trip_claim_6_1)
      end
    
      it "cannot decline trip claims regardless of their provider" do
        assert @scheduler.cannot?(:decline, @trip_claim_1_1)
        assert @scheduler.cannot?(:decline, @trip_claim_2_1)
        assert @scheduler.cannot?(:decline, @trip_claim_4_1)
        assert @scheduler.cannot?(:decline, @trip_claim_4_2)
        assert @scheduler.cannot?(:decline, @trip_claim_6_1)
      end
    end
    
    describe "trip ticket comments" do
      it "can use accessible_by to find trip ticket comments belonging to trip tickets from their own provider" do
        accessible = TripTicketComment.accessible_by(@scheduler)
        accessible.must_include @trip_ticket_comment_1_1

        accessible.wont_include @trip_ticket_comment_3_1
        accessible.wont_include @trip_ticket_comment_5_1
      end
    
      it "can create trip ticket comments on trip tickets belonging to their own provider" do
        assert @scheduler.can?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_1.id))
    
        assert @scheduler.cannot?(:create, TripTicketComment.new)
        assert @scheduler.cannot?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_3.id))
        assert @scheduler.cannot?(:create, TripTicketComment.new(:trip_ticket_id => @trip_ticket_5.id))
      end
    
      it "can read trip ticket comments belonging to trip_tickets from their own provider" do
        assert @scheduler.can?(:read, @trip_ticket_comment_1_1)
    
        assert @scheduler.cannot?(:read, @trip_ticket_comment_3_1)
        assert @scheduler.cannot?(:read, @trip_ticket_comment_5_1)
      end
    
      it "cannot update trip claims regardless of their provider" do    
        assert @scheduler.cannot?(:update, @trip_ticket_comment_1_1)
        assert @scheduler.cannot?(:update, @trip_ticket_comment_3_1)
        assert @scheduler.cannot?(:update, @trip_ticket_comment_5_1)
      end
    
      it "cannot destroy trip claims regardless of their provider" do    
        assert @scheduler.cannot?(:destroy, @trip_ticket_comment_1_1)
        assert @scheduler.cannot?(:destroy, @trip_ticket_comment_3_1)
        assert @scheduler.cannot?(:destroy, @trip_ticket_comment_5_1)
      end
    end
    
    describe "current user" do
      it "can read its own user record" do
        assert @scheduler.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @scheduler.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @scheduler.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @scheduler.cannot?(:deactivate, @current_user)
      end
    end    
    
    describe "users" do
      it "can use accessible_by to find only themselves" do
        accessible = User.accessible_by(@scheduler)
        accessible.must_include @current_user

        accessible.wont_include @user_1
        accessible.wont_include @user_2
        accessible.wont_include @user_3    
      end
    
      it "cannot create users regardless of their provider" do
        assert @scheduler.cannot?(:create, User.new)
        assert @scheduler.cannot?(:create, User.new(:provider_id => @provider_1.id))
        assert @scheduler.cannot?(:create, User.new(:provider_id => @provider_2.id))
        assert @scheduler.cannot?(:create, User.new(:provider_id => @provider_3.id))
      end
    
      it "cannot read other users regardless of their provider" do
        assert @scheduler.cannot?(:read, @user_1)
        assert @scheduler.cannot?(:read, @user_2)
        assert @scheduler.cannot?(:read, @user_3)    
      end
    
      it "cannot update users regardless of their provider" do
        assert @scheduler.cannot?(:update, @user_1)
        assert @scheduler.cannot?(:update, @user_2)
        assert @scheduler.cannot?(:update, @user_3)
      end
    
      it "cannot destroy any users regardless of provider" do
        assert @scheduler.cannot?(:destroy, @user_1)
        assert @scheduler.cannot?(:destroy, @user_2)
        assert @scheduler.cannot?(:destroy, @user_3)
      end
    
      it "cannot activate users regardless of their provider" do
        assert @scheduler.cannot?(:activate, @user_1)
        assert @scheduler.cannot?(:activate, @user_2)
        assert @scheduler.cannot?(:activate, @user_3)    
      end
      
      it "cannot deactivate users regardless of their provider" do
        assert @scheduler.cannot?(:deactivate, @user_1)
        assert @scheduler.cannot?(:deactivate, @user_2)
        assert @scheduler.cannot?(:deactivate, @user_3)
      end
      
      it "cannot set the role users regardless of their provider" do
        assert @scheduler.cannot?(:set_provider_role, @user_1)
        assert @scheduler.cannot?(:set_provider_role, @user_2)
        assert @scheduler.cannot?(:set_provider_role, @user_3)    
      end
    end
    
    describe "providers" do
      it "can use accessible_by to find their own provider and providers they have an approved relationship with" do
        accessible = Provider.accessible_by(@scheduler)
        accessible.must_include @provider_1
        accessible.must_include @provider_2
    
        accessible.wont_include @provider_3
      end
    
      it "cannot create providers" do
        assert @scheduler.cannot?(:create, Provider.new)
        assert @scheduler.cannot?(:create, Provider.new(:id => @provider_1.id))
      end
      
      it "can read their own provider or providers they have an approved relationship with" do
        assert @scheduler.can?(:read, @provider_1)
        assert @scheduler.can?(:read, @provider_2)
    
        assert @scheduler.cannot?(:read, @provider_3)
      end
      
      it "cannot update their own provider" do
        assert @scheduler.cannot?(:update, @provider_1)    
        assert @scheduler.cannot?(:update, @provider_2)
        assert @scheduler.cannot?(:update, @provider_3)
      end
      
      it "cannot destroy their own provider or any other provider" do
        assert @scheduler.cannot?(:destroy, @provider_1)
        assert @scheduler.cannot?(:destroy, @provider_2)
        assert @scheduler.cannot?(:destroy, @provider_3)
      end
      
      it "cannot view keys regardless of the provider" do
        assert @scheduler.cannot?(:keys, @provider_1)
        assert @scheduler.cannot?(:keys, @provider_2)
        assert @scheduler.cannot?(:keys, @provider_3)
      end
      
      it "cannot reset keys regardless of the provider" do
        assert @scheduler.cannot?(:reset_keys, @provider_1)
        assert @scheduler.cannot?(:reset_keys, @provider_2)
        assert @scheduler.cannot?(:reset_keys, @provider_3)
      end
    end
    
    describe "provider relationships" do
      it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
        accessible = ProviderRelationship.accessible_by(@scheduler)
        accessible.must_include @provider_relationship_1
        accessible.must_include @provider_relationship_3
    
        accessible.wont_include @provider_relationship_2
      end
    
      it "cannot create provider relationships regardless of the provider" do    
        assert @scheduler.cannot?(:create, ProviderRelationship.new)
        assert @scheduler.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))
        assert @scheduler.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
        assert @scheduler.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
      end
      
      it "can read provider relationships that their own provider belongs to" do
        assert @scheduler.can?(:read, @provider_relationship_1)
        assert @scheduler.can?(:read, @provider_relationship_3)
    
        assert @scheduler.cannot?(:read, @provider_relationship_2)
      end
      
      it "cannot update provider relationships regardless of the provider" do
        assert @scheduler.cannot?(:update, @provider_relationship_1)    
        assert @scheduler.cannot?(:update, @provider_relationship_2)
        assert @scheduler.cannot?(:update, @provider_relationship_3)
      end
      
      it "cannot destroy provider relationships regardless of the provider" do
        assert @scheduler.cannot?(:destroy, @provider_relationship_1)
        assert @scheduler.cannot?(:destroy, @provider_relationship_2)
        assert @scheduler.cannot?(:destroy, @provider_relationship_3)
      end
      
      it "cannot activate (aka approve) provider relationships regardless of the provider" do
        assert @scheduler.cannot?(:activate, @provider_relationship_1)
        assert @scheduler.cannot?(:activate, @provider_relationship_2)
        assert @scheduler.cannot?(:activate, @provider_relationship_3)
      end
    end
    
    describe "services" do
      it "can use accessible_by to load a list of services belonging to their own provider" do
        accessible = Service.accessible_by(@scheduler)
        accessible.must_include @service_1
    
        accessible.wont_include @service_2
        accessible.wont_include @service_3
      end
    
      it "cannot create services regardless of the provider" do        
        assert @scheduler.cannot?(:create, Service.new)
        assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_1.id))
        assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_2.id))
        assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_3.id))
      end
    
      it "can read services belonging to their own provider" do
        assert @scheduler.can?(:read, @service_1)
    
        assert @scheduler.cannot?(:read, @service_2)
        assert @scheduler.cannot?(:read, @service_3)
      end
    
      it "cannot update services regardless of the provider" do
        assert @scheduler.cannot?(:update, @service_1)
        assert @scheduler.cannot?(:update, @service_2)
        assert @scheduler.cannot?(:update, @service_3)
      end
    
      it "cannot destroy services regardless of their provider" do
        assert @scheduler.cannot?(:destroy, @service_1)
        assert @scheduler.cannot?(:destroy, @service_2)
        assert @scheduler.cannot?(:destroy, @service_3)
      end
    end
  end

  describe "dispatcher role" do
    setup do; end

    teardown do; end

    # TODO - when we know what the dispatcher permissions are
  end

  describe "csr role" do
    setup do; end

    teardown do; end
    
    # TODO - when we know what the CSR permissions are
  end
end
