class RequirementSet < ActiveRecord::Base
  belongs_to :provider
  has_many :eligibility_requirements

  accepts_nested_attributes_for :eligibility_requirements, :allow_destroy => true

  attr_accessible :boolean_type, :eligibility_requirements_attributes

  BOOLEAN_TYPES = {
    'and' => 'Customer must match all of the following:',
    'or' => 'Customer must match any of the following:'
  }

  validates :boolean_type, :presence => true, :inclusion => { :in => BOOLEAN_TYPES.keys }
end
