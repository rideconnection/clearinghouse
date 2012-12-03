module Clearinghouse
  class API_Info < Grape::API
    namespace :info do
      desc "Provides information about the API"
      get do
        { desc: "Clearinghouse Provider API", stable_version: 'v1' }
      end
    end
  end
end