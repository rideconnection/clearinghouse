require 'test_helper'

class AdminUserTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @user = FactoryGirl.create(:user)
    @other_user = FactoryGirl.create(:user, :name => "Muffin Bon Visor")
    @user.roles << Role.find_or_create_by_name!("site_admin")
    login_as(@user, :scope => :user)
  end

  teardown do
    User.destroy_all
    Provider.destroy_all
  end

  test "admin can create a new user and have password sent to user" do  
    visit "/"
    click_link "Admin"
    click_link "Users"
    click_link "New User"
    fill_in "user[email]", :with => "test@example.net"
    fill_in "user[password]", :with => "password 1"
    fill_in "user[password_confirmation]", :with => "password 1"
    fill_in "user[name]", :with => "Steve Smith"
    fill_in "user[title]", :with => "Manager"
    fill_in "user[phone]", :with => "1231231234"
    select "Microsoft", :from => "user[provider_id]"
    click_button "Create User"

    mail = ActionMailer::Base.deliveries.last

    assert page.has_content?("User was successfully created.")
    assert_equal mail.to.first, "test@example.net" 
    assert mail.body.include?("password 1")
  end

  test "admin can create a new user and have a password generated" do  
    visit "/"
    click_link "Admin"
    click_link "Users"
    click_link "New User"
    fill_in "user[email]", :with => "test@example.net"
    check "user[must_generate_password]"
    fill_in "user[name]", :with => "Steve Smith"
    fill_in "user[title]", :with => "Manager"
    fill_in "user[phone]", :with => "1231231234"
    select "Microsoft", :from => "user[provider_id]"
    click_button "Create User"

    mail = ActionMailer::Base.deliveries.last

    assert page.has_content?("User was successfully created.")
    assert_equal mail.to.first, "test@example.net" 
    assert mail.body.include?("Please set up a password")
  end

  test "user can change his password" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[password]', :with => 'n3w p4ssw0rd'
    fill_in 'user[password_confirmation]', :with => 'n3w p4ssw0rd'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
  end

  test "user cannot use insecure password" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[password]', :with => 'hello'
    fill_in 'user[password_confirmation]', :with => 'hello'
    click_button 'Update User'
    assert page.has_content?('Password is too short')
  end

  test "user can change email" do
    visit "/users/#{@user.id}/edit"
    fill_in 'user[email]', :with => 'user.changed@clearinghouse.org'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[email]').value == 'user.changed@clearinghouse.org'
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
    
    @user.roles.destroy_all
    
    visit "/users"
    assert !page.has_content?("Muffin Bon Visor")
  end
end
