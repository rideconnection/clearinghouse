require 'active_support/concern'

module ServiceLevelFilter
  extend ActiveSupport::Concern

  protected

  def service_level_filter(service)
    accommodations = service.mobility_accommodations.pluck(:mobility_impairment)
    if accommodations.blank?
      return nil, []
    else
      # does case-insensitive array search by converting to text, applying lowercase, then converting back to an array
      question_marks = (['?'] * accommodations.length).join(',')
      return %Q|(trip_tickets.customer_service_level IS NULL) OR (lower(trip_tickets.customer_service_level) = ANY(ARRAY[#{ question_marks }]))|,
        accommodations.map {|s| s.downcase }
    end
  end
end