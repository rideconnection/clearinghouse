# misc helper methods

class ActiveSupport::TestCase

  # helpers for testing ActiveRecord models

  def assert_accepts_values(obj, attr, *values)
    values.each do |value|
      obj.send("#{attr}=", value)
      obj.send(:password_confirmation=, value) if attr.to_sym == :password && obj.respond_to?(:password_confirmation=)
      obj.valid?
      obj.errors[attr].must_be_empty
    end
  end

  def assert_does_not_accept_values(obj, attr, *values)
    values.each do |value|
      obj.send("#{attr}=", value)
      obj.send(:password_confirmation=, value) if attr.to_sym == :password && obj.respond_to?(:password_confirmation=)
      obj.valid?.must_equal false
      obj.errors[attr].wont_be_empty
    end
  end

  def assert_attribute_required(obj, attr, valid = nil)
    obj.send("#{attr}=", nil)
    obj.send(:password_confirmation=, nil) if attr.to_sym == :password && obj.respond_to?(:password_confirmation=)
    obj.valid?.must_equal false
    obj.errors[attr].must_include "can't be blank"
    assert_accepts_values(obj, attr, valid) if valid
  end

  def assert_attribute_not_required(obj, attr)
    obj.send("#{attr}=", nil)
    obj.send(:password_confirmation=, nil) if attr.to_sym == :password && obj.respond_to?(:password_confirmation=)
    obj.valid?
    obj.errors[attr].must_be_empty
  end

  # for debugging Rack::Test cookies

  def rack_test_cookies
    rack_test_driver = Capybara.current_session.driver
    cookie_jar = rack_test_driver.browser.current_session.instance_variable_get(:@rack_mock_session).cookie_jar
    #puts "Current cookies: #{cookie_jar.instance_variable_get(:@cookies).map(&:inspect).join("\n")}"
    cookie_jar.instance_variable_get(:@cookies)
  end

  # for checking ActionMailer delivery results
  def validate_last_delivery(to, subject)
    msg = ActionMailer::Base.deliveries.last
    msg.wont_be_nil
    msg.to.must_equal to.is_a?(String) ? to.split(/,\s*/) : to
    msg.subject.must_equal subject
  end
end

module ActionDispatch
  class IntegrationTest
    def api_params(provider, additional_params = {})
      ApiParamFactory.authenticatable_params(provider, additional_params)
    end
  end
end
