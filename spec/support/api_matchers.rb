# additional_params should be a hash. The values don't need to be authentic, but some
# parameters are expected to match a certain data type or format.
shared_examples "requires authenticatable params" do  |*additional_params|
  method, url = description.split(' ')
  method = method.downcase.to_sym
  minimum_params = [:api_key, :nonce, :timestamp, :hmac_digest].inject({}) {|h, p| h.merge(p => "")}
  additional_params = Hash[*additional_params]
  all_params = minimum_params.merge(additional_params)
  
  # This still won't be an authenticatable request, but just make sure we are not getting HTTP 400
  it "is valid with min params" do
    send(method, url, all_params)
    expect(response.status).to_not eq(403)
    expect(response.body).not_to include("missing parameter:")
  end

  all_params.keys.each do |param|
    it "requires #{param} in params" do
      send(method, url, all_params.except(param))
      expect(response.status).to eq(403)
      expect(response.body).to include("missing parameter: #{param}")
    end
  end
end