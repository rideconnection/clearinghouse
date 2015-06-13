require 'entities_v1'

module Clearinghouse
  class API_v1 < Grape::API
    helpers APIHelpers
    include API_Authentication
  end
end

Dir[Rails.root.join("app/api/v1/*.rb")].each {|f| require f}
