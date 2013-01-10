require 'spec_helper'

describe Provider do
  before do
    @provider = FactoryGirl.create(:provider)
  end
  
  describe "instance methods" do
    it "should include a regenerate_keys! method" do
      @provider.should respond_to(:regenerate_keys!)
    end
  end
  
  describe "API key" do
    it "should not be required on new records" do
      provider = FactoryGirl.build(:provider, :api_key => nil)
      provider.valid?.should be_true
    end
    
    it "should be required on existing records" do
      @provider.api_key = nil
      @provider.valid?.should be_false
      @provider.errors.keys.should include(:api_key)
    end
    
    it "should be generated automagically for new records when no api_key has been set" do
      provider = FactoryGirl.build(:provider, :api_key => nil)
      provider.save
      provider.reload
      provider.api_key.should_not be_nil
    end
    
    it "should not be generated automagically for new records when an api_key *has* been set" do
      provider = FactoryGirl.build(:provider, :api_key => "somekey")
      provider.save
      provider.reload
      provider.api_key.should == "somekey"
    end
    
    it "should be able to be regenerated" do
      old_api_key = @provider.api_key
      @provider.regenerate_keys!
      @provider.reload
      @provider.api_key.should_not == old_api_key
    end
    
    it "must be unique" do
      provider = FactoryGirl.build(:provider, :api_key => @provider.api_key)
      provider.valid?.should be_false
      provider.errors.keys.should include(:api_key)
    end
  end
  
  describe "private key" do
    it "should not be required on new records" do
      provider = FactoryGirl.build(:provider, :private_key => nil)
      provider.valid?.should be_true
    end
    
    it "should be required on existing records" do
      @provider.private_key = nil
      @provider.valid?.should be_false
      @provider.errors.keys.should include(:private_key)
    end
    
    it "should be generated automagically for new records when no private_key has been set" do
      provider = FactoryGirl.build(:provider, :private_key => nil)
      provider.save
      provider.reload
      provider.private_key.should_not be_nil
    end
    
    it "should not be generated automagically for new records when an private_key *has* been set" do
      provider = FactoryGirl.build(:provider, :private_key => "somekey")
      provider.save
      provider.reload
      provider.private_key.should == "somekey"
    end
    
    it "should be able to be regenerated" do
      old_private_key = @provider.private_key
      @provider.regenerate_keys!
      @provider.reload
      @provider.private_key.should_not == old_private_key
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
  end

  it "should have an association to many nonces" do
    @provider.should respond_to(:nonces)
    nonce = FactoryGirl.build(:nonce)
    @provider.nonces << nonce
    @provider.nonces.should == [nonce]
  end
end
