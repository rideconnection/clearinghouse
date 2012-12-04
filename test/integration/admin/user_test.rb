require 'test_helper'

class UserTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!

  test "user can change his password" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit "/admin/users/#{user.id}/edit"
    fill_in 'user[password]', :with => 'n3w p4ssw0rd'
    fill_in 'user[password_confirmation]', :with => 'n3w p4ssw0rd'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
  end

  test "user cannot use insecure password" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit "/admin/users/#{user.id}/edit"
    fill_in 'user[password]', :with => 'hello'
    fill_in 'user[password_confirmation]', :with => 'hello'
    click_button 'Update User'
    assert page.has_content?('Password is too short')
  end

  test "user can change email" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit "/admin/users/#{user.id}/edit"
    fill_in 'user[email]', :with => 'user.changed@clearinghouse.org'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[email]').value == 'user.changed@clearinghouse.org'
  end

  test "user can change name" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit "/admin/users/#{user.id}/edit"
    fill_in 'user[name]', :with => 'Ned Stark'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[name]').value == 'Ned Stark'
  end

  test "user can change title" do
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user)
    visit "/admin/users/#{user.id}/edit"
    fill_in 'user[title]', :with => 'Lord of Winterfell'
    click_button 'Update User'
    assert page.has_content?('User was successfully updated.')
    assert find_field('user[title]').value == 'Lord of Winterfell'
  end
end
