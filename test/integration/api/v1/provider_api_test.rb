require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 provider endpoints" do
  before do
    @provider = FactoryGirl.create(:provider, :name => "Brovider", :primary_contact_email => "a@b.c")
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)
  end
  
  describe "GET /api/v1/provider" do
    include_examples "requires authenticatable params"

    it "should return the provider details" do
      get "/api/v1/provider", @minimum_request_params
      response.status.must_equal 200
      response.body.must_include %Q{"name":"#{@provider.name}"}
    end
  end

  describe "PUT /api/v1/provider" do
    include_examples "requires authenticatable params"

    it "should update the current provider" do
      put "/api/v1/provider", ApiParamFactory.authenticatable_params(@provider, {:provider => {:primary_contact_email => "c@b.a"}})
      response.status.must_equal 200
      response.body.must_include %Q{"primary_contact_email":"c@b.a"}
      @provider.reload
      @provider.primary_contact_email.must_equal "c@b.a"
    end

    it "should not allow me to update any other attribute" do
      put "/api/v1/provider", ApiParamFactory.authenticatable_params(@provider, {:provider => {:name => "Movider"}})
      response.status.must_equal 200
      response.body.wont_include %Q{"name":"Movider"}
      @provider.reload
      @provider.name.wont_equal "Movider"
    end
  end
end