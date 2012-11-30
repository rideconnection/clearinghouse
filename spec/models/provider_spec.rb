require 'spec_helper'

describe Provider do
  before do
    @provider = FactoryGirl.create(:provider)
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
      @provider.generate_api_key!
      @provider.reload
      @provider.api_key.should_not == old_api_key
    end
    
    it "must be unique" do
      provider = FactoryGirl.build(:provider, :api_key => @provider.api_key)
      provider.valid?.should be_false
      provider.errors.keys.should include(:api_key)
    end
  end
end
