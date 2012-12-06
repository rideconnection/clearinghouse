module Clearinghouse
  class API_v1 < Grape::API
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do
      namespace :originator do
        desc "Says hello"
        get :hello do
          "Hello, originator!"
        end
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