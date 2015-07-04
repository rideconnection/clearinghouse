# note: if you change files in test/support, restart Spork because they are loaded in the Spork.prefork block

require 'support/shared_examples'

# additional_params should be a hash. The values don't need to be authentic, but some
# parameters are expected to match a certain data type or format.
shared_examples "requires authenticatable params" do  |*additional_params|
  method, url = desc.split(' ')
  method = method.downcase.to_sym
  minimum_params = [:api_key, :nonce, :timestamp, :hmac_digest].inject({}) {|h, p| h.merge(p => "")}
  additional_params = Hash[*additional_params]
  all_params = minimum_params.merge(additional_params)
  
  # This still won't be an authenticatable request, but just make sure we are not getting HTTP 400
  it "is valid with min params" do
    send(method, url, all_params)
    response.status.wont_equal 403
    response.body.wont_include "missing parameter:"
    response.body.wont_match /"error":"\w+ is missing"/
  end

  all_params.keys.each do |param|
    it "requires #{param} in params" do
      send(method, url, all_params.except(param))
      response.status.must_equal 403
      response.body.must_include %("error":"#{param} is missing")
    end
  end
end
