require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 trip ticket comments endpoints" do
  before do
    @provider1 = FactoryGirl.create(:provider)
    @provider2 = FactoryGirl.create(:provider)
    @provider3 = FactoryGirl.create(:provider)
    FactoryGirl.create(:provider_relationship, requesting_provider: @provider1, cooperating_provider: @provider2)

    @user1 = FactoryGirl.create(:user, provider: @provider1)
    @user2 = FactoryGirl.create(:user, provider: @provider2)
    @user3 = FactoryGirl.create(:user, provider: @provider3)

    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider1)

    @trip_ticket1 = FactoryGirl.create(:trip_ticket, originator: @provider1)
    @trip_ticket2 = FactoryGirl.create(:trip_ticket, originator: @provider2)
    @trip_ticket3 = FactoryGirl.create(:trip_ticket, originator: @provider3)

    @trip_comment1 = FactoryGirl.create(:trip_ticket_comment, trip_ticket: @trip_ticket1, user: @user1, body: "comment one")
    @trip_comment2 = FactoryGirl.create(:trip_ticket_comment, trip_ticket: @trip_ticket2, user: @user1, body: "comment two")
    @trip_comment3 = FactoryGirl.create(:trip_ticket_comment, trip_ticket: @trip_ticket3, user: @user2, body: "comment three")
  end

  describe "GET /api/v1/trip_tickets/1/trip_ticket_comments" do
    include_examples "requires authenticatable params"

    context "when trip ticket was originated by the provider" do
      it "returns all trip comments belonging to the trip ticket" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_ticket_comments", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"body":"#{@trip_comment1.body}"}
      end

      it "does not return trip comments belonging to other trip tickets" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_ticket_comments", @minimum_request_params
        response.status.must_equal 200
        response.body.wont_include %Q{"body":"#{@trip_comment2.body}"}
      end
    end

    context "when trip ticket was originated by a related provider" do
      it "returns all trip comments belonging to the trip ticket" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_ticket_comments", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"body":"#{@trip_comment2.body}"}
      end
    end

    context "when trip ticket was originated by an unrelated provider" do
      it "returns a 401 access denied error" do
        get "/api/v1/trip_tickets/#{@trip_ticket3.id}/trip_ticket_comments", @minimum_request_params
        response.status.must_equal 401
        response.body.wont_include %Q{"body":"#{@trip_comment3.body}"}
      end
    end
  end

  describe "GET /api/v1/trip_tickets/1/trip_ticket_comments/1" do
    include_examples "requires authenticatable params"

    context "when trip ticket was originated by the provider" do
      it "returns the specified trip comment" do
        get "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_ticket_comments/#{@trip_comment1.id}", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"body":"#{@trip_comment1.body}"}
      end
    end

    context "when trip ticket was originated by a related provider" do
      it "returns the specified trip comment" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_ticket_comments/#{@trip_comment2.id}", @minimum_request_params
        response.status.must_equal 200
        response.body.must_include %Q{"body":"#{@trip_comment2.body}"}
      end
    end

    context "when trip ticket was originated by an unrelated provider" do
      it "returns a 401 access denied error" do
        get "/api/v1/trip_tickets/#{@trip_ticket3.id}/trip_ticket_comments/#{@trip_comment3.id}", @minimum_request_params
        response.status.must_equal 401
        response.body.wont_include %Q{"body":"#{@trip_comment3.body}"}
      end
    end

    context "when trip comment does not belong to specified trip ticket" do
      it "returns a 404 not found error" do
        get "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_claims/#{@trip_comment1.id}", @minimum_request_params
        response.status.must_equal 404
        response.body.wont_include %Q{"body":"#{@trip_comment1.body}"}
      end
    end
  end

  describe "POST /api/v1/trip_tickets/1/trip_ticket_comments" do
    include_examples "requires authenticatable params"

    let(:comment_params) {{
      body: "new comment",
      user_id: @user1.id
    }}

    context "when trip ticket was originated by the provider" do
      it "creates a trip comment" do
        post "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_ticket_comments",
             ApiParamFactory.authenticatable_params(@provider1, {trip_ticket_comment: comment_params})
        response.status.must_equal 201
        response.body.must_include %Q{"body":"new comment"}
      end
    end

    context "when trip ticket was originated by a related provider" do
      it "creates a trip comment" do
        post "/api/v1/trip_tickets/#{@trip_ticket2.id}/trip_ticket_comments",
             ApiParamFactory.authenticatable_params(@provider1, {trip_ticket_comment: comment_params})
        response.status.must_equal 201
        response.body.must_include %Q{"body":"new comment"}
      end
    end

    context "when trip ticket was originated by an unrelated provider" do
      it "returns a 401 access denied error" do
        post "/api/v1/trip_tickets/#{@trip_ticket3.id}/trip_ticket_comments",
             ApiParamFactory.authenticatable_params(@provider1, {trip_ticket_comment: comment_params})
        response.status.must_equal 401
        response.body.wont_include %Q{"body":"new comment"}
      end
    end
  end

  describe "PUT /api/v1/trip_tickets/1/trip_ticket_comments/1" do
    include_examples "requires authenticatable params"

    it "does not allow the API to update trip comments" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}/trip_ticket_comments/#{@trip_comment1.id}",
          ApiParamFactory.authenticatable_params(@provider1, {:trip_ticket_comment => {:body => "updated comment"}})
      response.status.must_equal 401
    end
  end
end