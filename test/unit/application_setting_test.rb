require 'test_helper'

class ApplicationSettingTest < ActiveSupport::TestCase
  teardown do
    ApplicationSetting.update_settings ApplicationSetting.defaults
    ApplicationSetting.apply!
  end
  
  describe "class methods" do
    describe "::update_settings" do
      it "should update only known params" do
        ApplicationSetting.update_settings({'foo' => "asdf"})

        assert_nil ApplicationSetting['foo']
      end

      it "should transform devise.expire_password_after to days when > 0" do
        ApplicationSetting.update_settings({'devise.expire_password_after' => 3})

        assert_equal 3.days, ApplicationSetting['devise.expire_password_after']
      end

      it "should set devise.expire_password_after to false when 0 is specified" do
        ApplicationSetting.update_settings({'devise.expire_password_after' => 0})

        assert_equal false, ApplicationSetting['devise.expire_password_after']
      end

      it "should transform devise.timeout_in to minutes when > 0" do
        ApplicationSetting.update_settings({'devise.timeout_in' => 3})

        assert_equal 3.minutes, ApplicationSetting['devise.timeout_in']
      end

      it "should set devise.timeout_in to nil when 0 is specified" do
        ApplicationSetting.update_settings({'devise.timeout_in' => 0})

        assert_nil ApplicationSetting['devise.timeout_in']
      end

      it "should not change unspecified settings" do
        ApplicationSetting['devise.timeout_in'] = 3

        ApplicationSetting.update_settings({'devise.expire_password_after' => 3})

        assert_equal 3, ApplicationSetting['devise.timeout_in']
      end
    end

    describe "::apply!" do
      it "should apply all currently saved settings to the application" do
        Devise.maximum_attempts         = 99
        Devise.password_archiving_count = 99
        Devise.expire_password_after    = 99
        Devise.timeout_in               = 99

        ApplicationSetting['devise.maximum_attempts']         = 1
        ApplicationSetting['devise.password_archiving_count'] = 2
        ApplicationSetting['devise.expire_password_after']    = 3
        ApplicationSetting['devise.timeout_in']               = 4
        
        ApplicationSetting.apply!

        assert_equal 1, Devise.maximum_attempts
        assert_equal 2, Devise.password_archiving_count
        assert_equal 3, Devise.expire_password_after
        assert_equal 4, Devise.timeout_in
      end
    end
  end
end
