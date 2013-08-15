require 'test_helper'
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

  let(:trip_claim4) do
    FactoryGirl.create(:provider_relationship, requesting_provider: @provider1, cooperating_provider: @provider3)
    FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket1, claimant: @provider3, notes: "claim four")
  end

  describe "GET /api/v1/trip_tickets/1/trip_claims" do
    include_examples "requires authenticatable params"

    context "when ticket was originated by the provider" do
      it "returns all trip claims belonging to the trip ticket" do
        trip_claim4
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"notes":"#{@trip_claim1.notes}"}
        response.body.must_include %Q{"notes":"#{trip_claim4.notes}"}
      end

      it "does not return trip claims belonging to other trip tickets" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims", @minimum_request_params
        response.status.must_equal 200
        response.body.wont_include %Q{"notes":"#{@trip_claim2.notes}"}
      end
    end

    context "when ticket was originated by another provider" do
      it "returns only trip claims belonging to the claimant" do
        trip_claim4
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims", ApiParamFactory.authenticatable_params(@provider2)
        response.status.must_equal 200
        response.body.must_include %Q{"notes":"#{@trip_claim1.notes}"}
        response.body.wont_include %Q{"notes":"#{trip_claim4.notes}"}
      end
    end
  end

  describe "GET /api/v1/trip_tickets/1/trip_claims/1" do
    include_examples "requires authenticatable params"

    context "when claim belongs to provider's own trip ticket" do
      it "returns the specified trip claim" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"notes":"#{@trip_claim1.notes}"}
      end
    end

    context "when claim belongs to a related provider's trip ticket" do
      context "when claim was created by the provider" do
        it "returns the specified trip claim" do
          get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}",
              ApiParamFactory.authenticatable_params(@provider2)
          response.status.must_equal 200
          response.body.must_include %Q{"notes":"#{@trip_claim1.notes}"}
        end
      end

      context "when claim was created by another provider" do
        it "returns a 401 access denied error" do
          get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{trip_claim4.id}",
              ApiParamFactory.authenticatable_params(@provider2)
          response.status.must_equal 401
          response.body.wont_include %Q{"notes":"#{trip_claim4.notes}"}
        end
      end
    end

    context "when trip claim does not belong to specified trip ticket" do
      it "returns a 404 not found error" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/#{@trip_claim1.id}", @minimum_request_params
        response.status.must_equal 404
        response.body.wont_include %Q{"notes":"#{@trip_claim1.notes}"}
      end
    end
  end

  describe "POST /api/v1/trip_tickets/1/trip_claims" do
    include_examples "requires authenticatable params"

    let(:claim_params) {{
      claimant_service_id: 1,
      status: :pending,
      proposed_pickup_time: Time.zone.now,
      proposed_fare: "$3.33"
    }}

    it "creates a trip claim" do
      post "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims",
           ApiParamFactory.authenticatable_params(@provider3, {trip_claim: claim_params})
      response.status.must_equal 201
      response.body.must_include %Q{"proposed_fare":"$3.33"}
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/1" do
    include_examples "requires authenticatable params"

    it "updates the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}",
          ApiParamFactory.authenticatable_params(@provider2, {:trip_claim => {:notes => "The sky is blue"}})
      response.status.must_equal 200
      response.body.must_include %Q{"notes":"The sky is blue"}
      @trip_claim1.reload
      @trip_claim1.notes.must_equal "The sky is blue"
    end

    it "does not allow updating a trip claim created by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}",
          ApiParamFactory.authenticatable_params(@provider1, {:trip_claim => {:notes => "The sky is falling"}})
      response.status.must_equal 401
      response.body.wont_include %Q{"notes":"The sky is falling"}
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/1/rescind" do
    include_examples "requires authenticatable params"

    it "rescinds the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/rescind",
          ApiParamFactory.authenticatable_params(@provider2)
      response.status.must_equal 200
      @trip_claim1.reload
      @trip_claim1.status.must_equal :rescinded
    end

    it "does not allow rescinding a trip claim created by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/rescind", @minimum_request_params
      response.status.must_equal 401
      @trip_claim1.reload
      @trip_claim1.status.must_equal :pending
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/1/decline" do
    include_examples "requires authenticatable params"

    it "declines the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/decline", @minimum_request_params
      response.status.must_equal 200
      @trip_claim1.reload
      @trip_claim1.status.must_equal :declined
    end

    it "does not allow a provider to decline their own trip claims" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/decline",
          ApiParamFactory.authenticatable_params(@provider2)
      response.status.must_equal 401
      @trip_claim1.reload
      @trip_claim1.status.must_equal :pending
    end

    it "does not allow declining trip claims for trips originated by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/decline",
          ApiParamFactory.authenticatable_params(@provider3)
      response.status.must_equal 401
      @trip_claim1.reload
      @trip_claim1.status.must_equal :pending
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_claims/1/approve" do
    include_examples "requires authenticatable params"

    it "approves the specified trip claim" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/approve", @minimum_request_params
      response.status.must_equal 200
      @trip_claim1.reload
      @trip_claim1.status.must_equal :approved
    end

    it "does not allow a provider to approve their own trip claims" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/approve",
          ApiParamFactory.authenticatable_params(@provider2)
      response.status.must_equal 401
      @trip_claim1.reload
      @trip_claim1.status.must_equal :pending
    end

    it "does not allow approving trip claims for trips originated by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{@trip_claim1.id}/approve",
          ApiParamFactory.authenticatable_params(@provider3)
      response.status.must_equal 401
      @trip_claim1.reload
      @trip_claim1.status.must_equal :pending
    end

    it "automatically declines other pending claims" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_claims/#{trip_claim4.id}/approve", @minimum_request_params
      @trip_claim1.reload
      @trip_claim1.status.must_equal :declined
    end
  end

end
