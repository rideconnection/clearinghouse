# Autoloading via application.rb causes issues with namespacing. See
# http://stackoverflow.com/a/7459807/83743
require 'api_authentication'
require 'api_helpers'
require 'api_info'
require 'api_v1'

module Clearinghouse
  class API < Grape::API
    prefix 'api'
    format :json
    default_format :json
    error_format :json
    rescue_from :all do |e|
      # Log it
      Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"
      
      # Notify external service of the error
      # Airbrake.notify(e)
      
      if e.class.name == "ValidationError"
        Rack::Response.new({ :error => e.message }, 400, { "Content-type" => "application/json" }).finish
      elsif Rails.env.production?
        Rack::Response.new({ :error => e.message }, 500, { "Content-type" => "application/json" }).finish
      else
        Rack::Response.new({ :error => e.message, :backtrace => e.backtrace }, 500, { 'Content-type' => 'application/json' }).finish
      end
    end
    
    scope :open_endpoints do
      mount API_Info
    end
    
    # In Grape, includes apply only to the namespace, scope, or version that
    # immediately follows the include. Putting it here, above a scope, with
    # all protected mount points inside of it, ensures that it will apply to
    # all of those mount points.
    include API_Authentication
    scope :protected_endpoints do
      mount API_v1
    end
  end
end