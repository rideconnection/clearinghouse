require 'test_helper'

class UsersTest < ActionController::IntegrationTest

  include Warden::Test::Helpers
  Warden.test_mode!
  
  setup do
    @provider = FactoryGirl.create(:provider, :name => "Microsoft")
    @password = "Password 1"

    @user = FactoryGirl.create(:user, 
      :password => @password, 
      :password_confirmation => @password, 
      :provider => @provider)
    @user.role = Role.find_or_create_by!(name: "provider_admin")
    @user.save!
  end
  
  test "users can edit their profile using the preferences url" do
    login_as @user, :scope => :user
    visit preferences_path
    current_path.must_equal edit_user_path(@user)
  end

  test "preferences url redirects user to login if necessary" do
    visit preferences_path
    current_path.must_equal new_user_session_path
    fill_in 'Email', :with => @user.email
    fill_in 'Password', :with => @password
    click_button 'Sign in'
    current_path.must_equal edit_user_path(@user)
  end

  test "user can set their notification preferences" do
    login_as @user, :scope => :user
    visit preferences_path
    [ 'Partner creates a trip ticket',
      'Claimed trip ticket rescinded',
      'Claimed trip ticket expired',
      'New trip claim awaiting approval',
      'New trip claim auto-approved',
      'Trip claim approved',
      'Trip claim declined',
      'Trip claim rescinded',
      'Trip result submitted',
      'Trip comment added' ].each do |opt|
      page.has_unchecked_field?(opt).must_equal true
    end

    check('Claimed trip ticket rescinded')
    check('Trip claim approved')
    click_button('Update User')

    visit preferences_path
    page.has_checked_field?('Claimed trip ticket rescinded').must_equal true
    page.has_checked_field?('Trip claim approved').must_equal true
    [ 'Partner creates a trip ticket',
      'Claimed trip ticket expired',
      'New trip claim awaiting approval',
      'New trip claim auto-approved',
      'Trip claim declined',
      'Trip claim rescinded',
      'Trip result submitted',
      'Trip comment added' ].each do |opt|
      page.has_unchecked_field?(opt).must_equal true
    end
  end

  test "user will receive notifications for enabled notification types" do
    login_as @user, :scope => :user
    visit preferences_path
    check('Trip comment added')
    click_button('Update User')

    trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider)

    visit new_trip_ticket_trip_ticket_comment_path(trip_ticket)
    fill_in 'Body', :with => 'This is a test comment 123'

    ActsAsNotifier::Config.disabled = false
    ActsAsNotifier::Config.use_delayed_job = false
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      click_button 'Create Trip ticket comment'
    end
  end

  test "user will not receive notifications for disabled notification types" do
    login_as @user, :scope => :user
    visit preferences_path
    check('Trip claim declined')
    click_button('Update User')

    trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider)

    visit new_trip_ticket_trip_ticket_comment_path(trip_ticket)
    fill_in 'Body', :with => 'This is a test comment 123'

    ActsAsNotifier::Config.disabled = false
    ActsAsNotifier::Config.use_delayed_job = false
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      click_button 'Create Trip ticket comment'
    end
  end
  
  test "user will be locked out after X number of failed login attempts" do
    maximum_attempts = Devise.maximum_attempts
    
    # We need to submit one additional time to see the locked error message
    (maximum_attempts + 1).times do |i|
      visit "/"
      fill_in 'Email', :with => @user.email
      fill_in 'Password', :with => "nope"
      click_button 'Sign in'
      current_path.must_equal new_user_session_path
      assert page.has_content?("Invalid email or password") if i < maximum_attempts
    end
    
    assert page.has_content?("Your account is locked")
  end
end
