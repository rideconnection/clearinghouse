require 'test_helper'

class TripTicketsControllerTest < ActionController::TestCase

  include Devise::TestHelpers

  let(:minimum_trip_params) {{
    customer_information_withheld: false,
    customer_dob: 25.years.ago,
    customer_gender: 'M',
    customer_first_name: 'Eins',
    customer_last_name: 'Letzte',
    customer_primary_phone: '123-456-7890',
    customer_seats_required: 1,
    origin_customer_id: 'abc123',
    scheduling_priority: 'pickup',
    requested_pickup_time: '6:00',
    requested_drop_off_time: '7:00',
    appointment_time: '7:15'
  }}

  setup do
    @provider = FactoryGirl.create(:provider)

    @user = FactoryGirl.create(:user, provider: @provider)
    @user.role = Role.find_or_create_by!(name: "provider_admin")
    @user.save!

    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in @user

    @trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider)
  end

  # TODO test index filtering

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trip_tickets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trip ticket" do
    assert_difference('TripTicket.count') do
      post :create, trip_ticket: minimum_trip_params
    end
    assert_redirected_to trip_ticket_path(assigns(:trip_ticket))
  end

  test "should show trip ticket" do
    get :show, id: @trip_ticket
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trip_ticket
    assert_response :success
  end

  test "should update trip ticket" do
    put :update, id: @trip_ticket, trip_ticket: { customer_first_name: 'Erst' }
    assert_redirected_to trip_ticket_path(assigns(:trip_ticket))
  end

  test "supports updating customer_identifiers hstore attribute" do
    put :update, id: @trip_ticket, trip_ticket: { customer_identifiers: { nickname: 'Little Bobby' }}
    @trip_ticket.reload.customer_identifiers.must_equal('nickname' => 'Little Bobby')
  end

  test "does not allow directly updating the status attribute" do
    ->{ put :update, id: @trip_ticket, trip_ticket: { status: :rescinded }}.must_raise(ActionController::UnpermittedParameters)
  end

  test "does not allow rescinding a trip by updating the rescinded attribute" do
    ->{ put :update, id: @trip_ticket, trip_ticket: { rescinded: true }}.must_raise(ActionController::UnpermittedParameters)
  end
end
