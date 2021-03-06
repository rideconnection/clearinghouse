require 'test_helper'

class UserTest < ActiveSupport::TestCase

  it "returns display_name based on available information" do
    user = User.new email: "new_guy@rideconnection.org", name: nil
    
    # If name is not available
    assert_equal "new_guy@rideconnection.org", user.display_name
    
    user.name = "Old Guy"
    assert_equal "Old Guy", user.display_name
  end

  describe '#new' do
    it "is active by default" do
      user = User.new
      user.active.must_equal true
      user.active_for_authentication?.must_equal true
    end
  end

  it "has a string_array field for notification_preferences which returns an array" do
    user = FactoryGirl.create(:user)
    assert_equal nil, user.notification_preferences
    user.notification_preferences = [:a, 'B', 1]
    user.save!
    user.reload
    # NOTE - Values are coerced to strings
    assert_equal ['a', 'B', '1'], user.notification_preferences
  end

  describe "validations" do
    setup do
      @user = FactoryGirl.create(:user)
      @provider = FactoryGirl.create(:provider)
      @role = FactoryGirl.create(:role)
    end

    it "should require a provider" do
      assert_attribute_required(@user, :provider, @provider)
    end
  
    it "should require a role" do
      assert_attribute_required(@user, :role, @role)
    end

    it "should require an email" do
      assert_attribute_required(@user, :email, "a@b.c")
    end

    describe "password" do
      it "must be a minimum 8 characters with at least one of each of the following: lower case alpha, upper case alpha, number, and non-alpha-numerical" do
        # Character requirements not met (H/T to http://www.ruby-doc.org/core-2.1.0/Array.html#method-i-combination)
        assert_does_not_accept_values(@user, :password, "aaaaaaaa")
        assert_does_not_accept_values(@user, :password, "AAAAAAAA")
        assert_does_not_accept_values(@user, :password, "11111111")
        assert_does_not_accept_values(@user, :password, "!!!!!!!!")
        assert_does_not_accept_values(@user, :password, "aAaAaAaA")
        assert_does_not_accept_values(@user, :password, "a1a1a1a1")
        assert_does_not_accept_values(@user, :password, "a!a!a!a!")
        assert_does_not_accept_values(@user, :password, "A1A1A1A1")
        assert_does_not_accept_values(@user, :password, "A!A!A!A!")
        assert_does_not_accept_values(@user, :password, "1!1!1!1!")
        assert_does_not_accept_values(@user, :password, "aA1aA1aA")
        assert_does_not_accept_values(@user, :password, "aA!aA!aA")
        assert_does_not_accept_values(@user, :password, "a1!a1!a1")
        assert_does_not_accept_values(@user, :password, "A1!A1!A1")

        # Too short
        assert_does_not_accept_values(@user, :password, "aA1!aA1")
        assert_does_not_accept_values(@user, :password, "aA1    ")
        
        # Too long
        assert_does_not_accept_values(@user, :password, "aA1!aA1!aA1!aA1!aA1!a")
        assert_does_not_accept_values(@user, :password, "aA1!!!!!!!!!!!!!!!!!!")

        # Just right
        assert_accepts_values(@user, :password, "aA1!aA1!")
        assert_accepts_values(@user, :password, "aA1 aA1 ")
        assert_accepts_values(@user, :password, "aA1!aA1!aA1!aA1!aA1!")
        assert_accepts_values(@user, :password, "aA1                 ")
      end
    
      it "cannot be reused until being changed 5 times" do
        @user.password = @user.password_confirmation = "Password 1"
        @user.valid?.must_equal false
        @user.errors.keys.must_include :password

        # Change the password 5 times
        Array(2..6).each do |i|
          @user.password = @user.password_confirmation = "Password #{i}"
          @user.save!
        end
        
        @user.password = @user.password_confirmation = "Password 1"
        @user.valid?.must_equal true
      end
    end
  end

end
