require 'base64'
require 'cgi'
require 'openssl'

module ApiParamFactory
  # Return the necessary parameters to make an authenticatable API call
  def self.authenticatable_params(provider, additional_params = {})
    Rails.logger.debug "additional_params: #{additional_params}"
    
    timestamp = Time.now.xmlschema
    nonce = provider.generate_nonce
    required_params = {
      api_key:     provider.api_key,
      nonce:       nonce,
      timestamp:   timestamp,
      hmac_digest: hmac_digest(provider.private_key, nonce, timestamp, hash_stringify(additional_params))
    }
    Rails.logger.debug "required_params: #{required_params}"

    flattened_params = hash_convert(additional_params)    
    Rails.logger.debug "flattened_params: #{flattened_params}"
    
    required_params.merge(flattened_params)
  end
  
  # Create an HMAC digest
  def self.hmac_digest(private_key, nonce, timestamp, request_params)
    Rails.logger.debug "Digesting request_params: #{request_params.to_json}"
    digest = OpenSSL::HMAC.hexdigest('sha1', private_key, [nonce, timestamp, request_params.to_json].join(':'))
    Rails.logger.debug "hmac_digest: #{digest}"
    digest
  end

  # Convert nested hash keys to flattened parameters, and turns all non-hash values to strings (because that's
  # how they'll be recieved on the API side)
  # Source: http://dev.mensfeld.pl/2012/01/converting-nested-hash-into-http-url-params-hash-version-in-ruby/
  def self.hash_convert(value, key = nil, out_hash = {})
    case value
    when Hash  then
      value.each { |k,v| hash_convert(v, append_key(key,k), out_hash) }
      out_hash
    when Array then
      value.each { |v| hash_convert(v, "#{key}[]", out_hash) }
      out_hash
    when nil   then ''
    else
      out_hash[key] = value.to_s
      out_hash
    end
  end

  def self.hash_stringify(value)
    case value
    when Hash  then
      value.each { |k,v| value[k] = hash_stringify(v) }
    when Array then
      value.collect { |v| hash_stringify(v) }
    when nil   then ''
    else
      value.to_s
    end
  end

  private

  def self.append_key(root_key, key)
    root_key.nil? ? :"#{key}" : :"#{root_key}[#{key.to_s}]"
  end
end