require 'base64'
require 'cgi'
require 'openssl'

RSpec::Matchers.define :require_request_params do |url, params|
  match do |_|
    get url
    response.status.should == 400
    # See https://github.com/dchelimsky/rspec/issues/25
    response.body.include?("missing parameter:")

    (params.length - 1).times do |i|
      params.to_a.combination(i+1).each do |c|
        get url, Hash[*c.flatten]
        response.status.should == 400
        response.body.include?("missing parameter:")
      end
    end

    get url, params
    response.status.should == 200
    !response.body.include?("missing parameter:")
  end
  
  failure_message_for_should do
    "expected URL #{url} to require #{params.keys.join(', ')} as the minimum parameters"
  end

  failure_message_for_should_not do
    "expected URL #{url} to not require #{params.keys.join(', ')} as the minimum parameters"
  end

  description do
    "require minimum parameters #{params.keys.join(', ')} for requests to URL #{url}"
  end
end

module ApiMacros
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
  end
  
  def protected_api_params(provider, additional_params = {})
    timestamp = Time.now.xmlschema
    nonce = api_nonce(provider)
    {
      api_key:     provider.api_key,
      nonce:       nonce,
      timestamp:   timestamp,
      hmac_digest: api_hmac_digest(provider.private_key, nonce, timestamp, additional_params)
    }.merge(additional_params)
  end
  
  def api_hmac_digest(private_key, nonce, timestamp, additional_params)
    additional_params.update(additional_params){|k,v| v.to_s}
    OpenSSL::HMAC.hexdigest('sha1', private_key, [nonce, timestamp, additional_params.to_json].join(':'))
  end
  
  def api_nonce(provider)
    begin
      nonce = SecureRandom.hex
    end while provider.nonces.exists?(nonce: nonce)
    nonce
  end
end