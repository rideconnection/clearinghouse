require 'test_helper'

describe "Clearinghouse::API_Info" do
  describe "GET /api/info" do
    it "should tell me about the API service" do
      get "/api/info"
      response.status.must_equal 200
      response.body.must_include "Clearinghouse Provider API"
    end
  end
end
