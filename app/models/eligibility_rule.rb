class EligibilityRule < ActiveRecord::Base
  belongs_to :eligibility_requirement

  attr_accessible :eligibility_requirement_id, :trip_field, :comparison_type, :comparison_value

  COMPARISON_TYPES = {
    'contain'       => 'must contain',
    'not_contain'   => 'must not contain',
    'equal'         => 'must equal',
    'not_equal'     => 'must not equal',
    'greater_than'  => 'must be greater than',
    'less_than'     => 'must be less than'
  }

  TRIP_TICKET_FIELDS = {
    'customer_dob'                    =>'Customer Age',
    'customer_impairment_description' => 'Customer Impairment Description',
    'customer_notes'                  => 'Customer Notes',
    'customer_primary_language'       => 'Customer Primary Language',
    'trip_notes'                      => 'Trip Notes',
    'trip_purpose_description'        => 'Trip Purpose Description',
  }.merge(TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELDS.inject({}) { |h, (k, v)| h[k.to_s] = v.pluralize; h })

  validates :trip_field, :presence => true, :inclusion => { :in => TRIP_TICKET_FIELDS.keys }
  validates :comparison_type, :presence => true, :inclusion => { :in => COMPARISON_TYPES.keys }
  validates :comparison_value, :presence => true
  validate :comparison_type_valid_for_field

  def sql_condition
    # age is special
    # array fields need special array field syntax
    # regular fields use normal SQL comparison syntax
    case trip_field
      when 'customer_dob'
        ''
      else
        ''
    end
  end

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
