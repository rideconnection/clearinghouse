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

    it "should include a regenerate_keys! method" do
      @provider.must_respond_to(:regenerate_keys!)
    end
  end

  describe "API key" do
    it "should not be required on new records" do
      assert_attribute_not_required(FactoryGirl.build(:provider), :api_key)
    end

    it "should be required on existing records" do
      assert_attribute_required(@provider, :api_key)
    end

    it "should be generated automagically for new records when no api_key has been set" do
      provider = FactoryGirl.build(:provider, :api_key => nil)
      provider.save
      provider.reload
      provider.api_key.wont_be_nil
    end

    it "should not be generated automagically for new records when an api_key *has* been set" do
      provider = FactoryGirl.build(:provider, :api_key => "somekey")
      provider.save
      provider.reload
      provider.api_key.must_equal "somekey"
    end

    it "should be able to be regenerated" do
      old_api_key = @provider.api_key
      @provider.regenerate_keys!
      @provider.reload
      @provider.api_key.wont_equal old_api_key
    end

    it "must be unique" do
      provider = FactoryGirl.build(:provider, :api_key => @provider.api_key)
      provider.valid?.must_equal false
      provider.errors.keys.must_include :api_key
    end
  end

  describe "private key" do
    it "should not be required on new records" do
      provider = FactoryGirl.build(:provider, :private_key => nil)
      provider.valid?.must_equal true
    end

    it "should be required on existing records" do
      @provider.private_key = nil
      @provider.valid?.must_equal false
      @provider.errors.keys.must_include :private_key
    end

    it "should be generated automagically for new records when no private_key has been set" do
      provider = FactoryGirl.build(:provider, :private_key => nil)
      provider.save
      provider.reload
      provider.private_key.wont_be_nil
    end

    it "should not be generated automagically for new records when an private_key *has* been set" do
      provider = FactoryGirl.build(:provider, :private_key => "somekey")
      provider.save
      provider.reload
      provider.private_key.must_equal "somekey"
    end

    it "should be able to be regenerated" do
      old_private_key = @provider.private_key
      @provider.regenerate_keys!
      @provider.reload
      @provider.private_key.wont_equal old_private_key
    end
  end

  describe "with an unapproved partnership" do
    before do
      @partner = FactoryGirl.create(:provider)
      @partnership = ProviderRelationship.create!(
        :requesting_provider => @provider,
        :cooperating_provider => @partner
      )
    end

    it "should know its approved partnerships" do
      assert @provider.approved_partnerships.empty?
      @partnership.approve!
      assert @provider.approved_partnerships.any?
    end

    it "should know which partnerships are pending approval and by whom" do
      assert_equal @provider.pending_partnerships_initiated_by_it, [@partnership]
      assert_equal @provider.partnerships_awaiting_its_approval, []

      assert_equal @partner.partnerships_awaiting_its_approval, [@partnership]
      assert_equal @partner.pending_partnerships_initiated_by_it, []
    end

    describe "#approved_partners" do
      it "should return a list of providers with approved partnerships" do
        assert @provider.approved_partners.empty?
        @partnership.approve!
        @provider.approved_partners.must_include(@partner)
      end
    end
  end


  describe "trip_ticket_expiration_days_before" do
    it "is not required" do
      provider = FactoryGirl.build(:provider, :trip_ticket_expiration_days_before => "")
      assert provider.valid?
    end
    
    it "must be greater than or equal to 0 if specified" do
      provider = FactoryGirl.build(:provider, :trip_ticket_expiration_days_before => -1)
      refute provider.valid?

      provider.trip_ticket_expiration_days_before = 0
      assert provider.valid?
    end
  end

  describe "trip_ticket_expiration_time_of_day" do
    it "is not required" do
      provider = FactoryGirl.build(:provider, :trip_ticket_expiration_time_of_day => "")
      assert provider.valid?
    end
    
    it "must be a valid time string" do
      provider = FactoryGirl.build(:provider, :trip_ticket_expiration_time_of_day => "-25:61")
      refute provider.valid?

      provider.trip_ticket_expiration_time_of_day = "23:59"
      assert provider.valid?
    end
  end

  it "should have an association to many nonces" do
    @provider.must_respond_to(:nonces)
    nonce = FactoryGirl.build(:nonce)
    @provider.nonces << nonce
    @provider.nonces.must_equal [nonce]
  end

end
