class EligibilityRequirement < ActiveRecord::Base
  belongs_to :provider
  has_many :eligibility_rules, :dependent => :destroy

  accepts_nested_attributes_for :eligibility_rules, :allow_destroy => true

  attr_accessible :boolean_type, :eligibility_rules_attributes

  BOOLEAN_TYPES = {
    'and' => 'Trip ticket must match all of the following:',
    'or' => 'Trip ticket must match any of the following:'
  }

  validates :boolean_type, :presence => true, :inclusion => { :in => BOOLEAN_TYPES.keys }
end
