# monkey patch OldPassword class to work with protected_attributes strict mode
# this won't be needed with strong parameters

OldPassword.class_eval do
  attr_accessible :encrypted_password, :password_salt
end
