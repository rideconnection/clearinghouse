require 'spec_helper'
require 'api_param_factory'

describe Clearinghouse::API_v1 do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)
  end
  
  context "originator" do
    describe "GET /api/v1/originator/hello" do
      include_examples "requires authenticatable params"
      
      it "should say hello" do
        get "/api/v1/originator/hello", @minimum_request_params
        response.status.should == 200
        response.body.should == "Hello, originator!"
      end
    end
  end

  context "claimant" do
    describe "GET /api/v1/claimant/hello" do
      include_examples "requires authenticatable params"

      it "should say hello" do
        get "/api/v1/claimant/hello", @minimum_request_params
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
      include_examples "requires authenticatable params"

      it "should return all provider users as JSON" do
        get "/api/v1/users", @minimum_request_params
        response.status.should == 200
        response.body.should include(%Q{"name":"#{@user1.name}"})
        response.body.should include(%Q{"name":"#{@user2.name}"})
      end
    end

    describe "GET /api/v1/users/show" do
      include_examples "requires authenticatable params", :id => 1

      it "should return the specified provider user as JSON" do
        get "/api/v1/users/show", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
        response.status.should == 200
        response.body.should include(%Q{"name":"#{@user1.name}"})
      end
    end
  end
end