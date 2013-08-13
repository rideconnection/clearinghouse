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
      it "requires a complex password" do
        # must be 6 - 20 characters in length and have at least one number and at least one non-alphanumeric character
        assert_does_not_accept_values(@user, :password, "aaaaaa")
        assert_does_not_accept_values(@user, :password, "aaa123")
        assert_does_not_accept_values(@user, :password, "aa  aa")
        assert_does_not_accept_values(@user, :password, "1---1")
        assert_does_not_accept_values(@user, :password, "aa 12")
        assert_does_not_accept_values(@user, :password, "aaaaaaaaaaaaaaaaaaa 1")

        assert_accepts_values(@user, :password, "aaaa 1")
        assert_accepts_values(@user, :password, "aa_123")
        assert_accepts_values(@user, :password, "1----1")
        assert_accepts_values(@user, :password, "aaa 12")
        assert_accepts_values(@user, :password, "11111111111111      ")
        assert_accepts_values(@user, :password, "aaaaaaaaaaaaaaaaaa 1")
      end
    end
  end

end
