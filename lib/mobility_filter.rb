module MobilityFilter
  protected

  def provider_mobility_filter(collection, provider)
    collection ||= TripTicket.all
    query_str = ""
    query_params = []
    provider.services.each do |service|
      new_sql, new_params = service_mobility_filter(service)
      if new_sql.present?
        query_str << " OR " if query_str.present?
        query_str << new_sql
        query_params = query_params + new_params
      end
    end
    query_str.blank? ? collection : collection.where("(customer_mobility_impairments IS NULL) OR #{query_str}", *query_params)
  end

  def service_mobility_filter(service)
    accommodations = service.mobility_accommodations.pluck(:mobility_impairment)
    if accommodations.blank?
      return nil, []
    else
      # does case-insensitive array search by converting to text, applying lowercase, then converting back to an array
      return "(lower(customer_mobility_impairments::text)::text[] <@ ARRAY[?])", [ accommodations.map {|s| "'#{s.downcase}'" }.join(',') ]
    end
  end
end