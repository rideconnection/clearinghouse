require 'test_helper'

class EligibilityRequirementTest < ActiveSupport::TestCase
  setup do
    @eligibility_requirement = FactoryGirl.create(:eligibility_requirement)
  end

  it "should validate the presence of service_id" do
    @eligibility_requirement.service_id = nil
    @eligibility_requirement.valid?.must_equal false
    @eligibility_requirement.errors.keys.must_include :service_id
  end

  it "should validate the presence of boolean_type" do
    @eligibility_requirement.boolean_type = nil
    @eligibility_requirement.valid?.must_equal false
    @eligibility_requirement.errors.keys.must_include :boolean_type
  end

  it "should validate that boolean_type is in accepted list" do
    @eligibility_requirement.boolean_type = EligibilityRequirement::BOOLEAN_TYPES.first[0]
    @eligibility_requirement.valid?.must_equal true
    @eligibility_requirement.boolean_type = "_not_valid_"
    @eligibility_requirement.valid?.must_equal false
    @eligibility_requirement.errors.keys.must_include :boolean_type
  end

  it "should accept nested attributes for eligibility_rules" do
    rule = FactoryGirl.create(:eligibility_rule)
    valid_attributes = rule.attributes
    valid_attributes.delete('id')
    valid_attributes.delete('eligibility_requirement_id')
    valid_attributes.delete('created_at')
    valid_attributes.delete('updated_at')
    @eligibility_requirement.update_attributes({ :eligibility_rules_attributes => { '0' => valid_attributes }})
    EligibilityRule.count.must_equal 2
  end
end
