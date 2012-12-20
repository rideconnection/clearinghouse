require 'api_param_factory'

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

        raise_authentication_error("api_key") unless current_provider
                
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

      # NOTE - If we send a param in the request like `:foo => {:bar => "baz"}` then params[:foo] will == "{:bar=>\"baz\"}"
      #        If we send it like `"foo[bar]" => "baz"` then params[:foo] == {:bar => "baz"}
      #        This causes problems when we create the digest based off of the latter format, because the HMAC we recreate on
      #        this end will be based on a nested hash, not a flattened request param. So either we can't use nested params,
      #        or the sending agent has to know to create the digest using the nested hash format, but send the values using
      #        the flat string format. See #hash_convert in /lib/api_param_factory.rb for an example of how to flatten a 
      #        nested hash.
      def authenticate_hmac_digest(hmac_digest, private_key, nonce, timestamp, request_params)
        hmac_digest == ApiParamFactory.hmac_digest(private_key, nonce, timestamp, request_params)
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