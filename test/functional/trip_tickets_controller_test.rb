require 'test_helper'

class TripTicketsControllerTest < ActionController::TestCase
  setup do
    @trip_ticket = trip_tickets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trip_tickets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trip_ticket" do
    assert_difference('TripTicket.count') do
      post :create, trip_ticket: { allowed_time_variance: @trip_ticket.allowed_time_variance, appointment_time: @trip_ticket.appointment_time, approved_claim_id: @trip_ticket.approved_claim_id, claimant_customer_id: @trip_ticket.claimant_customer_id, claimant_provider_id: @trip_ticket.claimant_provider_id, claimant_trip_id: @trip_ticket.claimant_trip_id, created_at: @trip_ticket.created_at, customer_address_id: @trip_ticket.customer_address_id, customer_boarding_time: @trip_ticket.customer_boarding_time, customer_deboarding_time: @trip_ticket.customer_deboarding_time, customer_dob: @trip_ticket.customer_dob, customer_emergency_phone: @trip_ticket.customer_emergency_phone, customer_impairment_description: @trip_ticket.customer_impairment_description, customer_information_withheld: @trip_ticket.customer_information_withheld, customer_fist_name: @trip_ticket.customer_first_name, customer_notes: @trip_ticket.customer_notes, customer_primary_phone: @trip_ticket.customer_primary_phone, customer_seats_required: @trip_ticket.customer_seats_required, drop_off_location_id: @trip_ticket.drop_off_location_id, earliest_pick_up_time: @trip_ticket.earliest_pick_up_time, mobility_type_id: @trip_ticket.mobility_type_id, num_attendants: @trip_ticket.num_attendants, num_guests: @trip_ticket.num_guests, origin_customer_id: @trip_ticket.origin_customer_id, origin_provider_id: @trip_ticket.origin_provider_id, origin_trip_id: @trip_ticket.origin_trip_id, pick_up_location_id: @trip_ticket.pick_up_location_id, scheduling_priority: @trip_ticket.scheduling_priority, trip_notes: @trip_ticket.trip_notes, trip_purpose_code: @trip_ticket.trip_purpose_code, trip_purpose_description: @trip_ticket.trip_purpose_description, updated_at: @trip_ticket.updated_at }
    end

    assert_redirected_to trip_ticket_path(assigns(:trip_ticket))
  end

  test "should show trip_ticket" do
    get :show, id: @trip_ticket
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trip_ticket
    assert_response :success
  end

  test "should update trip_ticket" do
    put :update, id: @trip_ticket, trip_ticket: { allowed_time_variance: @trip_ticket.allowed_time_variance, appointment_time: @trip_ticket.appointment_time, approved_claim_id: @trip_ticket.approved_claim_id, claimant_customer_id: @trip_ticket.claimant_customer_id, claimant_provider_id: @trip_ticket.claimant_provider_id, claimant_trip_id: @trip_ticket.claimant_trip_id, created_at: @trip_ticket.created_at, customer_address_id: @trip_ticket.customer_address_id, customer_boarding_time: @trip_ticket.customer_boarding_time, customer_deboarding_time: @trip_ticket.customer_deboarding_time, customer_dob: @trip_ticket.customer_dob, customer_emergency_phone: @trip_ticket.customer_emergency_phone, customer_impairment_description: @trip_ticket.customer_impairment_description, customer_information_withheld: @trip_ticket.customer_information_withheld, customer_first_name: @trip_ticket.customer_first_name, customer_notes: @trip_ticket.customer_notes, customer_primary_phone: @trip_ticket.customer_primary_phone, customer_seats_required: @trip_ticket.customer_seats_required, drop_off_location_id: @trip_ticket.drop_off_location_id, earliest_pick_up_time: @trip_ticket.earliest_pick_up_time, mobility_type_id: @trip_ticket.mobility_type_id, num_attendants: @trip_ticket.num_attendants, num_guests: @trip_ticket.num_guests, origin_customer_id: @trip_ticket.origin_customer_id, origin_provider_id: @trip_ticket.origin_provider_id, origin_trip_id: @trip_ticket.origin_trip_id, pick_up_location_id: @trip_ticket.pick_up_location_id, scheduling_priority: @trip_ticket.scheduling_priority, trip_notes: @trip_ticket.trip_notes, trip_purpose_code: @trip_ticket.trip_purpose_code, trip_purpose_description: @trip_ticket.trip_purpose_description, updated_at: @trip_ticket.updated_at }
    assert_redirected_to trip_ticket_path(assigns(:trip_ticket))
  end

  test "should destroy trip_ticket" do
    assert_difference('TripTicket.count', -1) do
      delete :destroy, id: @trip_ticket
    end

    assert_redirected_to trip_tickets_path
  end
end
