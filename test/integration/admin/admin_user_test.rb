require 'test_helper'

class AdminUserTest < ActionDispatch::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @user = FactoryGirl.create(:user)
    @other_user = FactoryGirl.create(:user, :name => "Muffin Bon Visor")
    @user.role = Role.find_or_create_by!(name: "site_admin")
    login_as(@user, :scope => :user)
  end

  teardown do
    User.destroy_all
    Provider.destroy_all
  end

  test "admin can create a new user without setting a password" do
    visit "/"
    click_link "Admin"
    click_link "Users"
    click_link "New User"
    fill_in "user[email]", :with => "test@example.net"
    fill_in "user[name]", :with => "Steve Smith"
    fill_in "user[title]", :with => "Manager"
    fill_in "user[phone]", :with => "1231231234"
    select "Microsoft", :from => "user[provider_id]"
    click_button "Create User"

    mail = ActionMailer::Base.deliveries.last

    assert page.has_content?("User was successfully created.")
    assert_equal mail.to.first, "test@example.net" 
    assert mail.body.include?("Confirm my account")
  end

  test "admin can edit another user and have a password reset email sent" do  
    visit "/users/#{@other_user.id}/edit"
    check "send_reset_password_instructions"
    click_button "Update User"

    mail = ActionMailer::Base.deliveries.last

    assert page.has_content?("User was successfully updated.")
    assert_equal mail.to.first, @other_user.email
    assert mail.body.include?("Someone has requested a link to change your password")
  end

  test "user can change his password" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[password]', :with => 'n3w p4ssw0rD'
    fill_in 'user[password_confirmation]', :with => 'n3w p4ssw0rD'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
  end

  test "user cannot use insecure password" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[password]', :with => 'hello'
    fill_in 'user[password_confirmation]', :with => 'hello'
    click_button 'Update User'
    assert page.has_content?('Password does not meet complexity requirements')
  end

  test "user can change email" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[email]', :with => 'user.changed@clearinghouse.org'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    # we require re-confirmation of email changes with Devise Confirmable
    #assert find_field('user[email]').value == 'user.changed@clearinghouse.org'
    @user.reload.unconfirmed_email.must_equal('user.changed@clearinghouse.org')
  end

  test "user can change name" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[name]', :with => 'Ned Stark'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[name]').value == 'Ned Stark'
  end

  test "user can change title" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[title]', :with => 'Lord of Winterfell'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[title]').value == 'Lord of Winterfell'
  end

  test "user can't view admin functions without proper permissions" do
    visit "/users"
    assert page.has_content?("Muffin Bon Visor")
    
    @user.role = FactoryGirl.create(:role, :name => "foo")
    @user.save!
    
    visit "/users"
    assert !page.has_content?("Muffin Bon Visor")
  end
  
  test "admin can enable an account that was previously disabled due to too many failed logins" do
    @other_user.update_attributes(locked_at: 1.day.ago)
    visit "/users/#{@other_user.id}/edit"
    check "unlock_account"
    click_button "Update User"
    assert page.has_content?('User was successfully updated.')

    @other_user.reload
    assert_equal 0, @other_user.failed_attempts
    assert_nil @other_user.locked_at
  end

  test "admin can deactivate an active user account" do
    visit "/users"
    find("a[href='#{deactivate_user_path(@other_user)}']").click
    assert page.has_content?('User was successfully updated.')
    refute @other_user.reload.active?
  end
  
  test "admin can activate an inactive user account" do
    @other_user.update_attribute :active, false
    visit "/users"
    find("a[href='#{activate_user_path(@other_user)}']").click
    assert page.has_content?('User was successfully updated.')
    assert @other_user.reload.active?
  end

  test "admin cannot deactivate their own account" do
    visit "/users"
    refute_selector "a[href='#{deactivate_user_path(@user)}']"
    assert page.has_content? "Active"
  end
end
