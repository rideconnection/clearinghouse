module Clearinghouse
  class API_v1 < Grape::API
    version 'v1', :using => :path, :vendor => 'clearinghouse', :format => :json
    
    rescue_from :all do |e|
      Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
    end
    
    resource :originator do
      desc "Says hello"
      get :hello do
        "Hello, originator!"
      end
    end
    
    resource :claimant do
      desc "Says hello"
      get :hello do
        "Hello, claimant!"
      end
    end
  end
end