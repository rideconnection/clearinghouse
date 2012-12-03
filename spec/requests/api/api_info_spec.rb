require 'spec_helper'

describe Clearinghouse::API_Info do
  describe "GET /api/info" do
    it "should tell me about the API service" do
      get "/api/info"
      response.status.should == 200
      response.body.should include("Clearinghouse Provider API")
    end
  end
end