module Clearinghouse
  class API_v1 < Grape::API
    version 'v1', :using => :path, :vendor => 'clearinghouse', :format => :json
    
    rescue_from :all do |e|
      # Log it
      Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"
      
      # Notify external service of the error
      # Airbrake.notify(e)
      
      # Send error and backtrace down to the client in the response body (only for internal/testing purposes of course)
      if !Rails.env.production?
        Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
      else
        Rack::Response.new({ :message => e.message, :backtrace => e.backtrace }, 500, { 'Content-type' => 'application/json' }).finish
      end
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