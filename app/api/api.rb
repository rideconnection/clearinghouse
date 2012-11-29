require "api_v1"

module Clearinghouse
  class API < Grape::API
    prefix 'api'
    format :json
    
    mount ::Clearinghouse::API_v1
  end
end