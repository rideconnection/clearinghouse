class Role < ActiveRecord::Base
  has_many :users

  # The set of roles that are meaningful inside a provider
  scope :provider_roles, ->{ where "name != 'site_admin'" }
  
  def is_admin_role?
    Role.is_admin_role?(self)
  end

  def is_read_only_role?
    Role.is_read_only_role?(self)
  end

  def self.is_admin_role?(role)
    role.name.to_sym == :site_admin
  end

  def self.is_read_only_role?(role)
    role.name.to_sym == :read_only
  end
end
