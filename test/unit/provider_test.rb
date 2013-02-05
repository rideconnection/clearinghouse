require 'test_helper'

class ProviderTest < ActiveSupport::TestCase
  setup do
    @provider = FactoryGirl.create(:provider)
  end
  
  describe "Provider instance" do
    it "knows if it can auto approve claims for a given provider" do
      provider_2 = FactoryGirl.create(:provider)
      r = ProviderRelationship.create!(
        :requesting_provider => @provider,
        :cooperating_provider => provider_2,
        :automatic_requester_approval => false,
        :automatic_cooperator_approval => true,
        :approved_at => Time.now
      )
      @provider.can_auto_approve_for?(provider_2).must_equal false
      provider_2.can_auto_approve_for?(@provider).must_equal true

      # Should work even if no relationship exists
      provider_3 = FactoryGirl.create(:provider)
      @provider.can_auto_approve_for?(provider_3).must_equal false
      provider_3.can_auto_approve_for?(@provider).must_equal false
    end
  end
end
