require 'test_helper'

class AdminProviderTest < ActionDispatch::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    @user = FactoryGirl.create(:user)
    @user.role = Role.find_or_create_by!(name: "site_admin")
    Role.find_or_create_by!(name: "provider_admin")
    @provider = FactoryGirl.create(:provider)
    login_as(@user, :scope => :user)
  end

  teardown do
    User.destroy_all
    Provider.destroy_all
  end

  test "site admin can create a new provider with a provider admin and have a password generated" do
    visit "/"
    click_link "Admin"
    click_link "Providers"
    click_link "New Provider"
    fill_in "provider[name]", :with => "Test User"
    fill_in "Address Line 1", :with => "123 Abc St"
    fill_in "City", :with => "Test"
    fill_in "State", :with => "FL"
    fill_in "Postal Code", :with => "12345"
    fill_in "Primary contact email", :with => "test@example.net"
    fill_in "Email", :with => "test@example.net"
    click_button "Create Provider"

    mail = ActionMailer::Base.deliveries.last

    assert page.has_content?("Provider was successfully created.")
    assert_equal mail.to.first, "test@example.net" 
    assert mail.body.include?("Please set up a password")
  end

  test "admin can deactivate an active provider" do
    visit "/providers"
    find("a[href='#{deactivate_provider_path(@provider)}']").click
    assert page.has_content?('Provider was successfully updated.')
    refute @provider.reload.active?
  end
  
  test "admin can activate an inactive provider" do
    @provider.update_attribute :active, false

    visit "/providers"
    find("a[href='#{activate_provider_path(@provider)}']").click
    assert page.has_content?('Provider was successfully updated.')
    assert @provider.reload.active?
  end  
end
