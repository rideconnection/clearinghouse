module Clearinghouse
  class API_Info < Grape::API
    namespace :info do
      desc "Provides information about the API"
      get do
        { description: "Clearinghouse Provider API", available_versions: ['v1'], current_version: 'v1' }
      end
    end
  end
end