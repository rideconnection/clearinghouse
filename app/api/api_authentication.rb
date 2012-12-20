require 'base64'
require 'cgi'
require 'openssl'

module API_Authentication
  def self.included(api)
    api.params do
      # TODO - Add more validations, i.e. length, format, etc.
      requires :api_key,     type: String, desc: "Your provider API key."
      
      unless Rails.env.development?
        requires :nonce,       type: String, desc: "Your unique request nonce."
        requires :timestamp,   type: String, desc: "The timestamp of your request."
        requires :hmac_digest, type: String, desc: "Your HMAC message digest."
      end
    end
    
    api.helpers do
      def current_provider
        @current_provider ||= authenticate_current_provider(params[:api_key])
      end

      def enforce_authentication_from_request_params
        api_key     = request.params.delete("api_key")
        nonce       = request.params.delete("nonce")
        timestamp   = request.params.delete("timestamp")
        hmac_digest = request.params.delete("hmac_digest")

        raise_authentication_error("api_key")     unless current_provider
        
        unless Rails.env.development?
          raise_authentication_error("nonce")       unless authenticate_nonce(nonce)
          raise_authentication_error("timestamp")   unless authenticate_timestamp(timestamp)
          raise_authentication_error("hmac_digest") unless authenticate_hmac_digest(hmac_digest, current_provider.private_key, nonce, timestamp, request.params)
        end
      end

      def authenticate_current_provider(api_key)
        Provider.find_by_api_key(api_key)
      end

      def authenticate_timestamp(timestamp)
        (5.minutes.ago.to_i..5.minutes.from_now.to_i).include?(Time.parse(timestamp).to_i)
      end

      def authenticate_hmac_digest(hmac_digest, private_key, nonce, timestamp, request_params)
        hmac_digest == OpenSSL::HMAC.hexdigest('sha1', private_key, [nonce, timestamp, request_params.to_json].join(':'))
      end

      def authenticate_nonce(nonce)
        @current_provider.nonces.exists?(nonce: nonce) ? false : @current_provider.nonces.create!(nonce: nonce)
      end
      
      def raise_authentication_error(source)
        raise(Grape::Exceptions::Base, message: "Could not authenticate #{source}", status: 403)
      end
    end
    
    api.after_validation do
      enforce_authentication_from_request_params
    end
  end
end