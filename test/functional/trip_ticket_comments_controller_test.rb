require 'test_helper'

class TripTicketCommentsControllerTest < ActionController::TestCase
  
  include Devise::TestHelpers

  setup do
    @provider = FactoryGirl.create(:provider)
    
    @user = FactoryGirl.create(:user, provider: @provider)
    @user.roles << Role.find_or_create_by_name!("provider_admin")
    @user.save!

    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in @user

    @trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider)
    @trip_ticket_comment = FactoryGirl.create(:trip_ticket_comment, trip_ticket: @trip_ticket)
  end

  test "should get index" do
    get :index, trip_ticket_id: @trip_ticket
    assert_response :success
    assert_not_nil assigns(:trip_ticket_comments)
  end

  test "should get new" do
    get :new, trip_ticket_id: @trip_ticket
    assert_response :success
  end

  test "should create trip_ticket_comment" do
    assert_difference('TripTicketComment.count') do
      post :create, trip_ticket_id: @trip_ticket, trip_ticket_comment: { body: @trip_ticket_comment.body }
    end

    assert_redirected_to trip_ticket_trip_ticket_comment_path(assigns(:trip_ticket), assigns(:trip_ticket_comment))
  end

  test "should show trip_ticket_comment" do
    get :show, trip_ticket_id: @trip_ticket, id: @trip_ticket_comment
    assert_response :success
  end

  test "should get edit" do
    get :edit, trip_ticket_id: @trip_ticket, id: @trip_ticket_comment
    assert_response :success
  end

  test "should update trip_ticket_comment" do
    put :update, trip_ticket_id: @trip_ticket, id: @trip_ticket_comment, trip_ticket_comment: { body: @trip_ticket_comment.body }
    assert_redirected_to trip_ticket_trip_ticket_comment_path(assigns(:trip_ticket), assigns(:trip_ticket_comment))
  end
end
