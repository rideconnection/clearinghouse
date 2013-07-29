require 'active_support/concern'

module MobilityFilter
  extend ActiveSupport::Concern

  protected

  def service_mobility_filter(service)
    accommodations = service.mobility_accommodations.pluck(:mobility_impairment)
    if accommodations.blank?
      return nil, []
    else
      # does case-insensitive array search by converting to text, applying lowercase, then converting back to an array
      question_marks = (['?'] * accommodations.length).join(',')
      return %Q|(trip_tickets.customer_mobility_impairments IS NULL) OR (lower(trip_tickets.customer_mobility_impairments::text)::text[] <@ ARRAY[#{ question_marks }])|,
        accommodations.map {|s| s.downcase }
    end
  end
end