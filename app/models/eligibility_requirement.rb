class EligibilityRequirement < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :service
  has_many :eligibility_rules, :dependent => :destroy

  accepts_nested_attributes_for :eligibility_rules, :allow_destroy => true

  BOOLEAN_TYPES = {
    'and' => 'Trip ticket must match all of the following:',
    'or' => 'Trip ticket must match any of the following:'
  }

  validates :service_id, :presence => true
  validates :boolean_type, :presence => true, :inclusion => { :in => BOOLEAN_TYPES.keys }
end
