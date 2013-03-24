require 'spec_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 trip claims endpoints" do
  before do
    @provider1 = FactoryGirl.create(:provider)
    @provider2 = FactoryGirl.create(:provider)
    @provider3 = FactoryGirl.create(:provider)
    FactoryGirl.create(:provider_relationship, requesting_provider: @provider1, cooperating_provider: @provider2)
    FactoryGirl.create(:provider_relationship, requesting_provider: @provider2, cooperating_provider: @provider3)

    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider1)

    @trip_ticket1 = FactoryGirl.create(:trip_ticket, originator: @provider1)
    @trip_ticket2 = FactoryGirl.create(:trip_ticket, originator: @provider2)
    @trip_ticket3 = FactoryGirl.create(:trip_ticket, originator: @provider3)

    @trip_claim1 = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket1, claimant: @provider2, notes: "claim one")
    @trip_claim2 = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket2, claimant: @provider1, notes: "claim two")
    @trip_claim3 = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket3, claimant: @provider2, notes: "claim three")
  end
  
  describe "GET /api/v1/trip_tickets/1/trip_claims/" do
    include_examples "requires authenticatable params"

    it "returns all trip claims belonging to the trip ticket" do
      get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/", @minimum_request_params
      response.status.should == 200
      response.body.should include(%Q{"notes":"#{@trip_claim1.notes}"})
      response.body.should_not include(%Q{"notes":"#{@trip_claim2.notes}"})
    end
  end

  describe "GET /api/v1/trip_tickets/1/trip_claims/show/" do
    include_examples "requires authenticatable params", :id => 1

    context "when claim belongs to provider's own trip ticket" do
      it "returns the specified trip claim" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/show",
            ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id})
        response.status.should == 200
        response.body.should include(%Q{"notes":"#{@trip_claim1.notes}"})
      end
    end

    context "when claim belongs related provider's trip ticket" do
      it "returns the specified trip claim" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/show/",
            ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim2.id})
        response.status.should == 200
        response.body.should include(%Q{"notes":"#{@trip_claim2.notes}"})
      end

      context "when claimant is an unrelated provider" do
        it "returns the specified trip claim" do
          get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/show/",
              ApiParamFactory.authenticatable_params(@provider3, {:id => @trip_claim2.id})
          response.status.should == 200
          response.body.should include(%Q{"notes":"#{@trip_claim2.notes}"})
        end
      end
    end

    context "when claim belongs to unrelated provider's trip ticket" do
      it "returns a 401 access denied error" do
        get "/api/v1/trip_tickets/#{@trip_ticket3.id}/trip_claims/show/",
            ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim3.id})
        response.status.should == 401
        response.body.should_not include(%Q{"notes":"#{@trip_claim3.notes}"})
      end
    end

    context "when trip claim does not belong to specified trip ticket" do
      it "returns a 404 not found error" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/show/",
            ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id})
        response.status.should == 404
        response.body.should_not include(%Q{"notes":"#{@trip_claim1.notes}"})
      end
    end
  end

  describe "POST /api/v1/trip_tickets/1/trip_claims/create/" do
    include_examples "requires authenticatable params"

    let(:claim_params) {{
      claimant_service_id: 1,
      status: :pending,
      proposed_pickup_time: DateTime.now,
      proposed_fare: "$3.33"
    }}

    it "creates a trip claim" do
      post "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/create/",
           ApiParamFactory.authenticatable_params(@provider3, {trip_claim: claim_params})
      response.status.should == 201
      response.body.should include(%Q{"proposed_fare":"$3.33"})
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/update/" do
    include_examples "requires authenticatable params", :id => 1

    it "updates the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/update/",
          ApiParamFactory.authenticatable_params(@provider2, {:id => @trip_claim1.id, :trip_claim => {:notes => "The sky is blue"}})
      response.status.should == 200
      response.body.should include(%Q{"notes":"The sky is blue"})
      @trip_claim1.reload
      @trip_claim1.notes.should eq("The sky is blue")
    end

    it "does not allow updating a trip claim created by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/update/",
          ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id, :trip_claim => {:notes => "The sky is falling"}})
      response.status.should == 401
      response.body.should_not include(%Q{"notes":"The sky is falling"})
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/rescind/" do
    include_examples "requires authenticatable params", :id => 1

    it "rescinds the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/rescind/",
          ApiParamFactory.authenticatable_params(@provider2, {:id => @trip_claim1.id})
      response.status.should == 200
      @trip_claim1.reload
      @trip_claim1.status.should eq(:rescinded)
    end

    it "does not allow rescinding a trip claim created by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/rescind/",
          ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id})
      response.status.should == 401
      @trip_claim1.reload
      @trip_claim1.status.should eq(:pending)
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/decline/" do
    include_examples "requires authenticatable params", :id => 1

    it "declines the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/decline/",
          ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id})
      response.status.should == 200
      @trip_claim1.reload
      @trip_claim1.status.should eq(:declined)
    end

    it "does not allow a provider to decline their own trip claims" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/decline/",
          ApiParamFactory.authenticatable_params(@provider2, {:id => @trip_claim1.id})
      response.status.should == 401
      @trip_claim1.reload
      @trip_claim1.status.should eq(:pending)
    end

    it "does not allow declining trip claims for trips originated by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/decline/",
          ApiParamFactory.authenticatable_params(@provider3, {:id => @trip_claim1.id})
      response.status.should == 401
      @trip_claim1.reload
      @trip_claim1.status.should eq(:pending)
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/approve/" do
    include_examples "requires authenticatable params", :id => 1

    it "approves the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/approve/",
          ApiParamFactory.authenticatable_params(@provider1, {:id => @trip_claim1.id})
      response.status.should == 200
      @trip_claim1.reload
      @trip_claim1.status.should eq(:approved)
    end

    it "does not allow a provider to approve their own trip claims" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/approve/",
          ApiParamFactory.authenticatable_params(@provider2, {:id => @trip_claim1.id})
      response.status.should == 401
      @trip_claim1.reload
      @trip_claim1.status.should eq(:pending)
    end

    it "does not allow approving trip claims for trips originated by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/approve/",
          ApiParamFactory.authenticatable_params(@provider3, {:id => @trip_claim1.id})
      response.status.should == 401
      @trip_claim1.reload
      @trip_claim1.status.should eq(:pending)
    end

    it "automatically declines other pending claims" do
      FactoryGirl.create(:provider_relationship, requesting_provider: @provider1, cooperating_provider: @provider3)
      trip_claim4 = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket1, claimant: @provider3, notes: "claim four")
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/approve/",
          ApiParamFactory.authenticatable_params(@provider1, {:id => trip_claim4.id})
      @trip_claim1.reload
      @trip_claim1.status.should eq(:declined)
    end
  end

end
