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

end