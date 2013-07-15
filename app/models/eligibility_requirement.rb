class EligibilityRequirement < ActiveRecord::Base
  belongs_to :requirement_set

  attr_accessible :requirement_set_id, :trip_field, :comparison_type, :comparison_value

  COMPARISON_TYPES = {
    'Must Equal' => 'equal',
    'Must Not Equal' => 'not_equal'
  }

  TRIP_TICKET_FIELDS = {
    'Eligibility Factors' => 'eligibility_factors',
    'Trip Purpose Description' => 'trip_purpose_description'
  }

  validates :trip_field, :presence => true, :inclusion => { :in => TRIP_TICKET_FIELDS.values }
  validates :comparison_type, :presence => true, :inclusion => { :in => COMPARISON_TYPES.values }
end
