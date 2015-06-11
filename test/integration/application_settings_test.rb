require 'test_helper'

class ApplicationSettingsTest < ActionDispatch::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    @admin = FactoryGirl.create(:user)
    @admin.role = Role.find_or_create_by!(name: "site_admin")
    @other_user = FactoryGirl.create(:user)
  end

  teardown do
    User.destroy_all
    ApplicationSetting.update_settings ApplicationSetting.defaults
    ApplicationSetting.apply!
  end
  
  test "application settings are applied on every request" do
    old_maximum_attempts = Devise.maximum_attempts
    Devise.maximum_attempts = 5
    
    ApplicationSetting['devise.maximum_attempts'] = 10
    
    visit "/"
    
    assert_equal 10, Devise.maximum_attempts
    
    Devise.maximum_attempts = old_maximum_attempts
  end
  
  test "only admins can access the application settings page" do
    login_as(@other_user, :scope => :user)
    visit application_settings_path
    
    current_path.wont_equal application_settings_path
    assert page.has_content?("You are not authorized to access that page")
  end
  
  describe "admin users" do
    before do
      login_as(@admin, :scope => :user)
    end

    test "admins can view and edit application settings" do
      visit application_settings_path
      
      assert page.has_content?("Maximum failed login attempts")
      assert page.has_content?("Password archiving count")
      assert page.has_content?("Expire password after")
      assert page.has_content?("Session timeout in")

      click_link "Edit Settings"
      
      fill_in "application_setting[devise.maximum_attempts]", :with => "1"
      fill_in "application_setting[devise.password_archiving_count]", :with => "2"
      fill_in "application_setting[devise.expire_password_after]", :with => "3"
      fill_in "application_setting[devise.timeout_in]", :with => "4"
      click_button "Update settings"
  
      assert page.has_content?("Application settings were successfully updated.")
      assert_equal 1, ApplicationSetting['devise.maximum_attempts']
      assert_equal 2, ApplicationSetting['devise.password_archiving_count']
      assert_equal 3.days, ApplicationSetting['devise.expire_password_after']
      assert_equal 4.minutes, ApplicationSetting['devise.timeout_in']
    end
  end
end
