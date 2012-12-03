require 'spec_helper'

describe Clearinghouse::API_v1 do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_params = minimum_protected_api_params(@provider)
  end
  
  context "originator" do
    describe "GET /api/v1/originator/hello" do
      it { should require_minimum_request_params("/api/v1/originator/hello", @minimum_params) }
      
      it "should say hello" do
        get "/api/v1/originator/hello", @minimum_params
        response.status.should == 200
        response.body.should == "Hello, originator!"
      end
    end
  end

  context "claimant" do
    describe "GET /api/v1/claimant/hello" do
      it { should require_minimum_request_params("/api/v1/claimant/hello", @minimum_params) }

      it "should say hello" do
        get "/api/v1/claimant/hello", @minimum_params
        response.status.should == 200
        response.body.should == "Hello, claimant!"
      end
    end
  end
end