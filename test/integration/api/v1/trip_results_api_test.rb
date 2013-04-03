require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 trip result endpoints" do
  # result can be updated by originator and claimant users (if an associated claim is specified)
  # users can read result that belongs to trip tickets of own provider or related provider

  describe "GET /api/v1/trip_tickets/1/trip_result" do
    it "is pending completion of trip result support in the main app"
  end

end
