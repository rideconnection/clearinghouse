module Clearinghouse
  class API_v1 < Grape::API
    helpers API_Authentication
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do
      params do
        use :authentication_params
      end

      namespace :claimant do
        desc "Says hello"
        get :hello do
          "Hello, claimant!"
        end
      end

    end
  end
end