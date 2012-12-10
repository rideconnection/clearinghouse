class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  attr_accessible :name

  # The set of roles that are meaningful inside a provider
  scope :provider_roles, :conditions => ['name != ?', 'site_admin']
end
