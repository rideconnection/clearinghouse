require 'spec_helper'

describe Clearinghouse::API_v1 do
  before do
    @provider = FactoryGirl.create(:provider)
    @request_params = protected_api_params(@provider)
  end
  
  context "originator" do
    describe "GET /api/v1/originator/hello" do
      it { should require_request_params("/api/v1/originator/hello", @provider) }
      
      it "should say hello" do
        get "/api/v1/originator/hello", @request_params
        response.status.should == 200
        response.body.should == "Hello, originator!"
      end
    end
  end

  context "claimant" do
    describe "GET /api/v1/claimant/hello" do
      it { should require_request_params("/api/v1/claimant/hello", @request_params) }

      it "should say hello" do
        get "/api/v1/claimant/hello", @request_params
        response.status.should == 200
        response.body.should == "Hello, claimant!"
      end
    end
  end

  context "users" do
    before do
      @user1 = FactoryGirl.create(:user, name: "Phil", provider: @provider)
      @user2 = FactoryGirl.create(:user, name: "Bill", provider: @provider)
    end
    
    describe "GET /api/v1/users" do
      it { should require_request_params("/api/v1/users", @request_params) }

      it "should return all provider users as JSON" do
        get "/api/v1/users", @request_params
        response.status.should == 200
        response.body.should include(%Q{"name":"#{@user1.name}"})
        response.body.should include(%Q{"name":"#{@user2.name}"})
      end
    end

    describe "GET /api/v1/users/show" do
      before do
        @request_params = protected_api_params(@provider, {:id => @user1.id})
      end

      it { should require_request_params("/api/v1/users/show", @request_params) }

      it "should return the specified provider user as JSON" do
        get "/api/v1/users/show", @request_params
        response.status.should == 200
        response.body.should include(%Q{"name":"#{@user1.name}"})
      end
    end
  end
end