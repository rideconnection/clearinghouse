require 'active_support/concern'
require 'eligibility_filter'
require 'service_area_filter'
require 'operating_hours_filter'

module ProviderServicesFilter
  extend ActiveSupport::Concern

  include EligibilityFilter
  include ServiceAreaFilter
  include OperatingHoursFilter

  # options:
  # :ignore_eligibility     - ignore eligibility, service area, and operating hours filters
  # :ignore_service_area    - ignore service area filtering
  # :ignore_operating_hours - ignore operating hours filtering

  def provider_services_filter(collection, provider, options = {})
    options ||= {}
    provider_query = ""
    provider_query_params = []
    service_area_query_present = false

    # ignore operating hours filters if provider has not yet defined any operating hours
    options[:ignore_operating_hours] ||= !provider.has_any_operating_hours?

    provider.services.each do |service|
      # for each service:
      # filter for service filters OR service filters OR etc.
      new_sql, new_params, service_area = provider_service_filter(service, options)
      if new_sql.present?
        provider_query << " OR " if provider_query.present?
        provider_query << new_sql
        provider_query_params = provider_query_params + new_params
        service_area_query_present ||= service_area
      end
    end

    if provider_query.present?
      # always show a user their own provider's trips so they can be managed
      provider_query = %Q{("trip_tickets"."origin_provider_id" = #{provider.id}) OR (#{provider_query})}
      collection = add_service_area_joins(collection) if service_area_query_present
      collection = collection.where([provider_query, *provider_query_params])
    end
    collection
  end

  def provider_service_filter(service, options = {})
    # within a service:
    # filter for accommodated impairments AND eligible AND within service area AND within operating hours
    eligibility_query, eligibility_params = service_eligibility_filter(service) unless options[:ignore_eligibility]
    service_area_query = service_area_filter(service) unless options[:ignore_eligibility] || options[:ignore_service_area]
    operating_hours_query = service_operating_hours_filter(service) unless options[:ignore_eligibility] || options[:ignore_operating_hours]

    queries_array = [ eligibility_query, service_area_query, operating_hours_query ].map {|x| x.presence }.compact
    combined_query = queries_array.map {|x| "(#{x})"}.join(' AND ')
    combined_params = (eligibility_params || [])

    return combined_query, combined_params, service_area_query.present?
  end

end
