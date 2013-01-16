require 'test_helper'

class TripClaimsControllerTest < ActionController::TestCase
  setup do
    @trip_claim = trip_claims(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trip_claims)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trip_claim" do
    assert_difference('TripClaim.count') do
      post :create, trip_claim: { name: @trip_claim.name }
    end

    assert_redirected_to trip_claim_path(assigns(:trip_claim))
  end

  test "should show trip_claim" do
    get :show, id: @trip_claim
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trip_claim
    assert_response :success
  end

  test "should update trip_claim" do
    put :update, id: @trip_claim, trip_claim: { name: @trip_claim.name }
    assert_redirected_to trip_claim_path(assigns(:trip_claim))
  end

  test "should destroy trip_claim" do
    assert_difference('TripClaim.count', -1) do
      delete :destroy, id: @trip_claim
    end

    assert_redirected_to trip_claims_path
  end
end
