require 'test_helper'

class NonceTest < ActiveSupport::TestCase
  before do
    @provider = FactoryGirl.create(:provider)
    @nonce = FactoryGirl.build(:nonce)
  end
  
  describe "class methods" do
    describe "#cleanup" do
      before do
        @nonce_01 = FactoryGirl.create(:nonce, created_at: 1.day.ago)
        @nonce_31 = FactoryGirl.create(:nonce, created_at: 31.days.ago)
      end
      
      it "should be defined" do
        Nonce.must_respond_to :cleanup
      end
      
      it "should destroy all nonces more than 30 days old" do
        Nonce.all.must_include @nonce_01, @nonce_31
        Nonce.cleanup.must_equal [@nonce_31]
        Nonce.all.wont_include @nonce_31
      end
    end
  end
  
  it "should have an association to a provider" do
    @nonce.must_respond_to :provider
    @nonce.provider = @provider
    @nonce.provider.must_equal @provider
  end
  
  describe "nonce" do
    it "should be unique within the scope of the provider" do
      nonce = "my_nonce"
      @nonce.nonce = nonce
      @nonce.provider = @provider
      @nonce.save
      
      nonce2 = FactoryGirl.build(:nonce, nonce: nonce, provider: @provider)
      nonce2.valid?.must_equal false
      nonce2.errors.keys.must_include :nonce

      provider2 = FactoryGirl.build(:provider)
      nonce2.provider = provider2
      nonce2.valid?.must_equal true
    end
  end
end
