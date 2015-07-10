require 'test_helper'

class EligibilityRequirementsIntegrationTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider)
    FactoryGirl.create(:service, provider: @provider)
    @user = FactoryGirl.create(:user, provider: @provider)
    @user.role = Role.find_or_create_by!(name: "provider_admin")
    @user.save!

    login_as @user, scope: :user
  end
  
  test "provider admin can create eligibility requirements for provider" do
    visit provider_path(@provider)
    click_link "Create New Eligibility Requirements Group"
    select "must equal", from: :eligibility_requirement_eligibility_rules_attributes_0_comparison_type
    fill_in :eligibility_requirement_eligibility_rules_attributes_0_comparison_value, with: "0"
    click_button "Create Eligibility Requirements Group"
    assert page.has_content? "Eligibility Requirements Group was successfully created"
  end
end