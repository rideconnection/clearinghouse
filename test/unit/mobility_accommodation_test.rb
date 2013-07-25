require 'test_helper'

class MobilityAccommodationTest < ActiveSupport::TestCase
  setup do
    @mobility_accommodation = FactoryGirl.create(:mobility_accommodation)
  end

  it "should validate that service_id is not blank" do
    @mobility_accommodation.service_id = nil
    @mobility_accommodation.valid?.must_equal false
    @mobility_accommodation.errors.keys.must_include :service_id
  end

  it "should validate that mobility_impairment is not blank" do
    @mobility_accommodation.mobility_impairment = ''
    @mobility_accommodation.valid?.must_equal false
    @mobility_accommodation.errors.keys.must_include :mobility_impairment
  end
end
