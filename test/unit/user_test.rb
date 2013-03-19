require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Some test still exist in spec/models/user_spec.rb
  
  it "returns display_name based on available information" do
    user = User.new email: "new_guy@rideconnection.org", name: nil
    
    # If name is not available
    assert_equal "new_guy@rideconnection.org", user.display_name
    
    user.name = "Old Guy"
    assert_equal "Old Guy", user.display_name
  end
  
  describe "validations" do
    setup do
      @user = FactoryGirl.create(:user)
      @provider = FactoryGirl.create(:provider)
      @role = FactoryGirl.create(:role)
    end
    
    it "should require a provider" do  
      @user.provider = nil
      @user.valid?.must_equal false
      @user.errors[:provider].must_include "can't be blank"
      
      @user.provider = @provider
      @user.valid?.must_equal true
    end
  
    it "should require a role" do
      @user.role = nil
      @user.valid?.must_equal false
      @user.errors[:role].must_include "can't be blank"
      
      @user.role = @role
      @user.valid?.must_equal true
    end
  end
end
