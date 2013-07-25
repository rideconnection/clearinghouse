require 'test_helper'

class EligibilityRuleTest < ActiveSupport::TestCase
  setup do
    @eligibility_rule = FactoryGirl.create(:eligibility_rule)
  end

  it "should validate presence of trip_field" do
    @eligibility_rule.trip_field = nil
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :trip_field
  end

  it "should validate that trip_field is in accepted list" do
    @eligibility_rule.trip_field = EligibilityRule::TRIP_TICKET_FIELDS.first[0]
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = "_not_valid_"
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_type
  end

  it "should validate presence of comparison_type" do
    @eligibility_rule.comparison_type = nil
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_type
  end

  it "should validate that comparison_type is in accepted list" do
    @eligibility_rule.comparison_type = 'equal'
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = "_not_valid_"
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_type
  end

  it "should validate presence of comparison_value" do
    @eligibility_rule.comparison_value = nil
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_value
  end

  it "should validate that customer_dob field is used with equality and numeric comparisons" do
    @eligibility_rule.trip_field = 'customer_dob'
    @eligibility_rule.comparison_type = 'equal'
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = 'greater_than'
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = 'contain'
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_type
  end

  it "should validate that array fields are used with contains and equality comparisons" do
    @eligibility_rule.trip_field = TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.keys.first.to_s
    @eligibility_rule.comparison_type = 'equal'
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = 'contain'
    @eligibility_rule.valid?.must_equal true
    @eligibility_rule.comparison_type = 'greater_than'
    @eligibility_rule.valid?.must_equal false
    @eligibility_rule.errors.keys.must_include :comparison_type
  end
end
