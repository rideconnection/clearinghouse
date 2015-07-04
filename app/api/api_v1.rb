require 'entities_v1'

Dir[Rails.root.join("app/api/v1/*.rb")].each {|f| require f}

module Clearinghouse
  class API_v1 < Grape::API
    helpers APIHelpers

    after_validation do
      enforce_authentication_from_request_params
    end
  end
end
