require 'spec_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 users endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)

    @user1 = FactoryGirl.create(:user, name: "Phil", active: true, provider: @provider)
    @user2 = FactoryGirl.create(:user, name: "Bill", provider: @provider)
    @user3 = FactoryGirl.create(:user, name: "Mark", provider: FactoryGirl.create(:provider))
  end
  
  describe "GET /api/v1/users" do
    include_examples "requires authenticatable params"

    it "should return all provider users as JSON" do
      get "/api/v1/users", @minimum_request_params
      response.status.should == 200
      response.body.should include(%Q{"name":"#{@user1.name}"})
      response.body.should include(%Q{"name":"#{@user2.name}"})
      response.body.should_not include(%Q{"name":"#{@user3.name}"})
    end
  end

  describe "GET /api/v1/users/show" do
    include_examples "requires authenticatable params", :id => 1

    it "should return the specified provider user as JSON" do
      get "/api/v1/users/show", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
      response.status.should == 200
      response.body.should include(%Q{"name":"#{@user1.name}"})
    end

    it "should not allow me to access a user belonging to another provider" do
      get "/api/v1/users/show", ApiParamFactory.authenticatable_params(@provider, {:id => @user3.id})
      response.status.should == 404
      response.body.should_not include(%Q{"name":"#{@user3.name}"})
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

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/update", ApiParamFactory.authenticatable_params(@provider, {:id => @user3.id, :user => {:name => "Mary"}})
      response.status.should == 404
      response.body.should_not include(%Q{"name":"Mary"})
    end
  end

  describe "PUT /api/v1/users/activate" do
    before do
      @user1.update_attribute(:active, false)
    end
    
    include_examples "requires authenticatable params", :id => 1

    it "should activate the specified provider user and return the user as JSON" do
      put "/api/v1/users/activate", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
      response.status.should == 200
      response.body.should include(%Q{"active":true})
      @user1.reload
      @user1.active.should be_true
    end

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/activate", ApiParamFactory.authenticatable_params(@provider, {:id => @user3.id})
      response.status.should == 404
      response.body.should_not include(%Q{"active":true"})
    end
  end

  describe "PUT /api/v1/users/deactivate" do      
    before do
      @user1.update_attribute(:active, true)
    end
    
    include_examples "requires authenticatable params", :id => 1

    it "should deactivate the specified provider user and return the user as JSON" do
      put "/api/v1/users/deactivate", ApiParamFactory.authenticatable_params(@provider, {:id => @user1.id})
      response.status.should == 200
      response.body.should include(%Q{"active":false})
      @user1.reload
      @user1.active.should be_false
    end

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/deactivate", ApiParamFactory.authenticatable_params(@provider, {:id => @user3.id})
      response.status.should == 404
      response.body.should_not include(%Q{"active":false"})
    end
  end
end