require 'spec_helper'

describe Clearinghouse::API do
  context "originator" do
    describe "GET /api/v1/originator/hello" do
      it "says hello" do
        get "/api/v1/originator/hello"
        response.status.should == 200
        response.body.should == "Hello, originator!"
      end
    end
  end

  context "claimant" do
    describe "GET /api/v1/claimant/hello" do
      it "says hello" do
        get "/api/v1/claimant/hello"
        response.status.should == 200
        response.body.should == "Hello, claimant!"
      end
    end
  end
end