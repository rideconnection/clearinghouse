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
      @user1 = FactoryGirl.create(:user, name: "Phil", active: true, provider: @provider)
    end
    
    describe "GET /api/v1/users" do
      before do
        @user2 = FactoryGirl.create(:user, name: "Bill", provider: @provider)
      end

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

    describe "PUT /api/v1/users/update" do
      include_examples "requires authenticatable params", :id => 1

      it "should update the specified provider user and return the user as JSON" do
        put "/api/v1/users/update", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id, :user => {:name => "Mary"}})
        response.status.should == 200
        response.body.should include(%Q{"name":"Mary"})
        @user1.reload
        @user1.name.should eq("Mary")
      end
    end

    describe "PUT /api/v1/users/activate" do
      before do
        @user1 = FactoryGirl.create(:user, name: "Phil", active: false, provider: @provider)
      end
      
      include_examples "requires authenticatable params", :id => 1

      it "should activate the specified provider user and return the user as JSON" do
        put "/api/v1/users/activate", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
        response.status.should == 200
        response.body.should include(%Q{"active":true})
        @user1.reload
        @user1.active.should be_true
      end
    end

    describe "PUT /api/v1/users/deactivate" do      
      before do
        @user1 = FactoryGirl.create(:user, name: "Phil", active: true, provider: @provider)
      end
      
      include_examples "requires authenticatable params", :id => 1

      it "should deactivate the specified provider user and return the user as JSON" do
        put "/api/v1/users/deactivate", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
        response.status.should == 200
        response.body.should include(%Q{"active":false})
        @user1.reload
        @user1.active.should be_false
      end
    end
  end
end