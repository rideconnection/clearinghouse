require 'spec_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 provider endpoints" do
  before do
    @provider = FactoryGirl.create(:provider, :name => "Brovider")
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)

    @user1 = FactoryGirl.create(:user, provider: @provider)
    @user2 = FactoryGirl.create(:user, provider: @provider)

    @provider.primary_contact = @user1
    @provider.save
  end
  
  describe "GET /api/v1/provider" do
    include_examples "requires authenticatable params"

    it "should return the provider details" do
      get "/api/v1/provider", @minimum_request_params
      response.status.should == 200
      response.body.should include(%Q{"name":"#{@provider.name}"})
    end
  end

  describe "PUT /api/v1/provider/update" do
    include_examples "requires authenticatable params"

    it "should update the current provider" do
      put "/api/v1/provider/update", ApiParamFactory.authenticatable_params(@provider, {:provider => {:primary_contact_id => "#{@user2.id}"}})
      response.status.should == 200
      response.body.should include(%Q{"primary_contact_id":#{@user2.id}})
      @provider.reload
      @provider.primary_contact.should eq(@user2)
    end

    it "should not allow me to update any other attribute" do
      put "/api/v1/provider/update", ApiParamFactory.authenticatable_params(@provider, {:provider => {:name => "Movider"}})
      response.status.should == 200
      response.body.should_not include(%Q{"name":"Movider"})
      @provider.reload
      @provider.name.should_not eq("Movider")
    end
  end
end