require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 claimant endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
  end
  
  describe "GET /api/v1/claimant/hello" do
    include_examples "requires authenticatable params"

    it "should say hello" do
      get "/api/v1/claimant/hello", api_params(@provider)
      response.status.must_equal 200
      response.body.must_equal %("Hello, claimant!")
    end
  end
end