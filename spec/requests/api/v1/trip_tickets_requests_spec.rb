require 'spec_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 trip tickets endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)

    @trip_ticket1 = FactoryGirl.create(:trip_ticket, customer_first_name: "Dom", originator: @provider)
    @trip_ticket2 = FactoryGirl.create(:trip_ticket, customer_first_name: "Arthur", originator: @provider)
    @trip_ticket3 = FactoryGirl.create(:trip_ticket, customer_first_name: "Mal", originator: FactoryGirl.create(:provider))
  end
  
  describe "GET /api/v1/trip_tickets" do
    include_examples "requires authenticatable params"

    it "should return all trip tickets originated by the provider as JSON" do
      get "/api/v1/trip_tickets", @minimum_request_params
      response.status.should == 200
      response.body.should include(%Q{"customer_first_name":"#{@trip_ticket1.customer_first_name}"})
      response.body.should include(%Q{"customer_first_name":"#{@trip_ticket2.customer_first_name}"})
      response.body.should_not include(%Q{"customer_first_name":"#{@trip_ticket3.customer_first_name}"})
    end
  end

  describe "GET /api/v1/trip_tickets/1" do
    include_examples "requires authenticatable params"

    it "should return the specified trip ticket as JSON" do
      get "/api/v1/trip_tickets/#{@trip_ticket1.id}", ApiParamFactory.authenticatable_params(@provider)
      response.status.should == 200
      response.body.should include(%Q{"customer_first_name":"#{@trip_ticket1.customer_first_name}"})
    end

    it "should not allow me to access a trip ticket originated by another provider" do
      get "/api/v1/trip_tickets/#{@trip_ticket3.id}", ApiParamFactory.authenticatable_params(@provider)
      response.status.should == 401
      response.body.should_not include(%Q{"customer_first_name":"#{@trip_ticket3.customer_first_name}"})
    end
  end

  describe "PUT /api/v1/trip_tickets/1" do
    include_examples "requires authenticatable params"

    let(:trip_params) {{ trip_ticket: {
      customer_first_name: "Ariadne"
    }}}

    it "should update the specified trip ticket and return the trip ticket as JSON" do
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}", ApiParamFactory.authenticatable_params(@provider, trip_params)
      response.status.should == 200
      response.body.should include(%Q{"customer_first_name":"Ariadne"})
      @trip_ticket1.reload
      @trip_ticket1.customer_first_name.should eq("Ariadne")
    end

    it "updates a nested location" do
      trip_params[:trip_ticket][:pick_up_location_attributes] = {
        address_1: '456 New Rd', city: 'Boston', state: 'MA', zip: '02134'
      }
      put "/api/v1/trip_tickets/#{@trip_ticket1.id}", ApiParamFactory.authenticatable_params(@provider, trip_params)
      response.status.should == 200
      response.body.should include(%Q{"address_1":"456 New Rd"})
      @trip_ticket1.reload
      @trip_ticket1.pick_up_location.address_1.should eq("456 New Rd")
    end

    it "should not allow me to update a trip ticket originated by another provider" do
      put "/api/v1/trip_tickets/#{@trip_ticket3.id}", ApiParamFactory.authenticatable_params(@provider, trip_params)
      response.status.should == 401
      response.body.should_not include(%Q{"customer_first_name":"Ariadne"})
    end
  end

  describe "POST /api/v1/trip_tickets" do
    include_examples "requires authenticatable params"

    let(:trip_params) {{ trip_ticket: {
      customer_information_withheld: false,
      customer_dob: "2012-01-01",
      customer_first_name: "First",
      customer_last_name: "Last",
      customer_primary_phone: "555-555-5555",
      customer_seats_required: 1,
      origin_customer_id: "newtrip123",
      requested_drop_off_time: Time.now,
      requested_pickup_time: Time.now,
      scheduling_priority: "pickup"
    }}}

    it "creates a trip ticket" do
      post "/api/v1/trip_tickets", ApiParamFactory.authenticatable_params(@provider, trip_params)
      response.status.should == 201
      response.body.should include(%Q{"origin_customer_id":"newtrip123"})
    end

    it "creates a nested location" do
      trip_params[:trip_ticket][:pick_up_location_attributes] = {
        address_1: '456 New Rd', city: 'Boston', state: 'MA', zip: '02134'
      }
      post "/api/v1/trip_tickets", ApiParamFactory.authenticatable_params(@provider, trip_params)
      response.status.should == 201
      response.body.should include(%Q{"address_1":"456 New Rd"})
    end
  end

  # TODO pending implementation of a TripTicket#cancel method
  #describe "PUT /api/v1/trip_tickets/1/cancel" do
  #  include_examples "requires authenticatable params"
  #
  #  it "should cancel the specified trip ticket and return the trip ticket as JSON" do
  #    put "/api/v1/trip_tickets/#{@trip_ticket1.id}/cancel", ApiParamFactory.authenticatable_params(@provider)
  #    response.status.should == 200
  #    response.body.should include(%Q{"canceled":true})
  #    @trip_ticket1.reload
  #    @trip_ticket1.canceled.should be_true
  #  end
  #
  #  it "should not allow me to cancel a trip ticket originated by another provider" do
  #    put "/api/v1/trip_tickets/#{@trip_ticket3.id}/cancel", ApiParamFactory.authenticatable_params(@provider)
  #    response.status.should == 401
  #    response.body.should_not include(%Q{"canceled":true"})
  #  end
  #end
end
