require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Some test still exist in spec/models/user_spec.rb
  
  describe "user provider" do
    setup do
      @provider = FactoryGirl.create(:provider)
      @user = FactoryGirl.build(:user, :provider_id => nil)
      @site_admin = FactoryGirl.create(:role, :name => "site_admin")
    end
    
    teardown do
      @site_admin.destroy
      @provider.destroy
    end
    
    it "should require a provider_id when a user is not a site_admin" do
      @user.valid?.must_equal false
      @user.errors[:provider_id].must_include "is required for all non-administrative users"
      
      @user.provider = @provider
      @user.valid?.must_equal true
    end
  
    it "should not require a provider when a user is a site_admin" do
      @user.roles << @site_admin
      @user.valid?.must_equal true
    end
  end
end
