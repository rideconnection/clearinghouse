require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 claimant endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)
  end
  
  describe "GET /api/v1/claimant/hello" do
    include_examples "requires authenticatable params"

    it "should say hello" do
      get "/api/v1/claimant/hello", @minimum_request_params
      response.status.must_equal 200
      response.body.must_equal "Hello, claimant!"
    end
  end
end