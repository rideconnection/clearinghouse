require 'spec_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 originator endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
    @minimum_request_params = ApiParamFactory.authenticatable_params(@provider)
  end
  
  describe "GET /api/v1/originator/hello" do
    include_examples "requires authenticatable params"
    
    it "should say hello" do
      get "/api/v1/originator/hello", @minimum_request_params
      response.status.should == 200
      response.body.should == "Hello, originator!"
    end
  end
end