class EligibilityRule < ActiveRecord::Base
  belongs_to :eligibility_requirement
  has_one :service, :through => :eligibility_requirement

  attr_accessible :eligibility_requirement_id, :trip_field, :comparison_type, :comparison_value

  COMPARISON_TYPES = {
    'contain'       => 'must contain',
    'not_contain'   => 'must not contain',
    'equal'         => 'must equal',
    'not_equal'     => 'must not equal',
    'greater_than'  => 'must be greater than',
    'less_than'     => 'must be less than'
  }

  DESIRED_TRIP_TICKET_ARRAY_FIELDS = [
      :customer_eligibility_factors,
      :customer_mobility_factors,
      :trip_funders
  ]
  TRIP_TICKET_ARRAY_FIELDS = TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.select {|k,v| DESIRED_TRIP_TICKET_ARRAY_FIELDS.include?(k) }

  TRIP_TICKET_FIELDS = {
    'customer_dob'                    => 'Customer Age',
    'customer_service_level'          => 'Service Level',
    'trip_purpose_description'        => 'Trip Purpose Description'
  }.merge(TRIP_TICKET_ARRAY_FIELDS.inject({}) { |h, (k, v)| h[k.to_s] = v.pluralize; h })

  validates :trip_field, :presence => true, :inclusion => { :in => TRIP_TICKET_FIELDS.keys }
  validates :comparison_type, :presence => true, :inclusion => { :in => COMPARISON_TYPES.keys }
  validates :comparison_value, :presence => true
  validate :comparison_type_valid_for_field

  def self.comparisons_for_field(field_name)
    if field_name == 'customer_dob'
      [ 'equal', 'not_equal', 'greater_than', 'less_than']
    elsif TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.with_indifferent_access[field_name].present?
      [ 'contain', 'not_contain', 'equal', 'not_equal' ]
    else
      COMPARISON_TYPES.keys
    end
  end

  protected

  def comparison_type_valid_for_field
    errors[:comparison_type] << "not valid for trip ticket field #{TRIP_TICKET_FIELDS[trip_field]}" if !self.class.comparisons_for_field(trip_field).include?(comparison_type)
  end
end
