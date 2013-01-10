require 'test_helper'

class ProviderTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider)
    @password = "password 1"
    @user = FactoryGirl.create(:user, :password => @password, :password_confirmation => @password, :provider => @provider)
    @user.roles = [Role.find_or_create_by_name!("provider_admin")]
    @user.save!
  end

  test "provider_admin can create users, triggering an email" do
    @user.roles << Role.find_or_create_by_name!("site_admin")
    login_as(@user, :scope => :user)
    visit '/'
    click_link "Admin"
  end

  test "provider_admin user can view keys" do
    login_as(@user, :scope => :user)
    visit "/providers/#{@user.provider.id}/keys"
    assert page.has_content?(@provider.api_key)
    assert page.has_content?(@provider.private_key)
  end

  test "non-provider_admin user cannot view keys" do
    user = FactoryGirl.create(:user, :provider => @provider)
    login_as(user, :scope => :user)
    assert_raise(CanCan::AccessDenied) {
      visit "/providers/#{user.provider.id}/keys"
    }
  end

  test "provider_admin user cannot reset keys without accepting conditions" do
    login_as(@user, :scope => :user)
    visit "/providers/#{@user.provider.id}/keys"
    fill_in 'reset_keys[password]', :with => @password
    click_button 'Reset API Keys'
    assert page.has_content?("must accept the disclaimer")
  end

  test "provider_admin user cannot reset keys without entering password" do
    login_as(@user, :scope => :user)
    visit "/providers/#{@user.provider.id}/keys"
    check 'reset_keys[accept]'
    click_button 'Reset API Keys'
    assert page.has_content?("must enter your password")
  end

  test "provider_admin user can reset keys" do
    old_api_key = @provider.api_key
    old_private_key = @provider.private_key
    
    login_as(@user, :scope => :user)
    visit "/providers/#{@user.provider.id}/keys"
    check 'reset_keys[accept]'
    fill_in 'reset_keys[password]', :with => @password
    click_button 'Reset API Keys'
    
    @provider.reload
    assert page.has_no_content?(old_api_key)
    assert page.has_no_content?(old_private_key)
    assert page.has_content?(@provider.api_key)
    assert page.has_content?(@provider.private_key)
    assert page.has_content?("API keys have been regenerated")
  end

  # test "non-admin user can't access provider keys" do
  #   user = FactoryGirl.create(:user)
  #   
  #   visit "/users/#{user.id}/edit"
  #   fill_in 'user[password]', :with => 'n3w p4ssw0rd'
  #   fill_in 'user[password_confirmation]', :with => 'n3w p4ssw0rd'
  #   click_button 'Update User'
  #   assert page.has_content?('User was successfully updated.')
  # end
  # 
  # test "user cannot use insecure password" do
  #   user = FactoryGirl.create(:user)
  #   login_as(user, :scope => :user)
  #   visit "/users/#{user.id}/edit"
  #   fill_in 'user[password]', :with => 'hello'
  #   fill_in 'user[password_confirmation]', :with => 'hello'
  #   click_button 'Update User'
  #   assert page.has_content?('Password is too short')
  # end
  # 
  # test "user can change email" do
  #   user = FactoryGirl.create(:user)
  #   login_as(user, :scope => :user)
  #   visit "/users/#{user.id}/edit"
  #   fill_in 'user[email]', :with => 'user.changed@clearinghouse.org'
  #   click_button 'Update User'
  #   assert page.has_content?('User was successfully updated.')
  #   assert find_field('user[email]').value == 'user.changed@clearinghouse.org'
  # end
  # 
  # test "user can change name" do
  #   user = FactoryGirl.create(:user)
  #   login_as(user, :scope => :user)
  #   visit "/users/#{user.id}/edit"
  #   fill_in 'user[name]', :with => 'Ned Stark'
  #   click_button 'Update User'
  #   assert page.has_content?('User was successfully updated.')
  #   assert find_field('user[name]').value == 'Ned Stark'
  # end
  # 
  # test "user can change title" do
  #   user = FactoryGirl.create(:user)
  #   login_as(user, :scope => :user)
  #   visit "/users/#{user.id}/edit"
  #   fill_in 'user[title]', :with => 'Lord of Winterfell'
  #   click_button 'Update User'
  #   assert page.has_content?('User was successfully updated.')
  #   assert find_field('user[title]').value == 'Lord of Winterfell'
  # end
end
