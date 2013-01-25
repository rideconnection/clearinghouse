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
    rescue_from :all do |e|
      # Log it
      Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"
      
      # TODO - Notify external service of the error
      # Airbrake.notify(e)
      
      message = { :error => e.message }
      status = 500
      if e.is_a? Grape::Exceptions::ValidationError
        status = 403
      elsif e.is_a? ActiveRecord::RecordNotFound
        status = 404
      end
      if !Rails.env.production?
        message = message.merge({ :backtrace => e.backtrace })
      end
      
      Rack::Response.new(message, status, { 'Content-type' => 'application/json' }).finish
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
