module Clearinghouse
  class API_v1 < Grape::API
    # helpers APIHelpers
    # include API_Authentication
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do

      namespace :claimant do
        desc "Says hello"
        get :hello do
          "Hello, claimant!"
        end
      end

    end
  end
end