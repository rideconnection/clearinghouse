module TripTicketsFilter

  def trip_tickets_filter(collection, provider)
    collection ||= TripTicket.scoped
    init_trip_ticket_trip_time_filter_values

    # Apply rescinded filter at the end so we can apply default if not
    # specified. Note that if ticket_status is specified, the rescinded param
    # will be deleted
    rescinded_filter = nil
    
    # If we're filtering by trip ticket status we need to unset some other
    # filters that could cause conflicting results.
    ticket_status_filter = nil
    if params[:trip_ticket_filters].try(:[], :ticket_status).try(:length)
      params[:trip_ticket_filters].delete(:claim_status)
      params[:trip_ticket_filters].delete(:rescinded)
    end

    params[:trip_ticket_filters].try(:each) do |filter, value|
      case filter.to_sym
      when :seats_required
        collection = collection.filter_by_seats_required(value) unless value.try(:[], "min").blank? && value.try(:[], "max").blank?
      when :trip_time
        unless value[:start].blank? && value[:end].blank?
          collection = collection.filter_by_trip_time(
            parse_trip_ticket_trip_time(value[:start], Time.zone.at(0)),
            parse_trip_ticket_trip_time(value[:end], Time.zone.at(9_999_999_999))
          )
        end
      when :updated_at
        unless value[:start].blank? && value[:end].blank?
          collection = collection.filter_by_updated_at(
            parse_trip_ticket_trip_time(value[:start], Time.zone.at(0)),
            parse_trip_ticket_trip_time(value[:end], Time.zone.at(9_999_999_999))
          )
        end
      when :rescinded
        rescinded_filter = value
      when :ticket_status
        ticket_status_filter = Array(value).compact
      else
        if !value.blank? && TripTicket.respond_to?("filter_by_#{filter.to_s}")
          collection = collection.send("filter_by_#{filter.to_s}", value)
        end
      end
    end

    # expects 'exclude_rescinded', 'only_rescinded', or 'include_rescinded'/nil (default)
    # 'include_rescinded' is the same as saying 'do not filter', so does nothing
    collection = collection.filter_by_rescinded(rescinded_filter) unless ['include_rescinded', nil].include?(rescinded_filter)
    
    # We need to apply this filter last so that we're iterating over as few
    # records as possible.
    collection = collection.filter_by_ticket_status(ticket_status_filter, provider) unless ticket_status_filter.nil?
    
    collection
  end

  def parse_trip_ticket_trip_time(datetime_value, default)
    Time.zone.parse(datetime_value) rescue default
  end

  # trip_ticket_filters_present? returns true if any non-blank trip ticket filters are contained in the params.
  # this is needed because the filtering code inserts placeholders for certain filters that are logically blank (see
  # init_trip_ticket_trip_time_filter_values). this needs to be kept up-to-date when similar placeholders are added.
  def trip_ticket_filters_present?
    filters = params[:trip_ticket_filters].try(:clone) || {}
    trip_time = filters.delete(:trip_time)
    seats_required = filters.delete(:seats_required)
    filters.present? ||
      trip_time.try(:[], :start).present? ||
      trip_time.try(:[], :end).present? ||
      seats_required.try(:[], :min).present? ||
      seats_required.try(:[], :max).present?
  end

  private

  def init_trip_ticket_trip_time_filter_values
    params[:trip_ticket_filters]                     ||= Hash.new
    params[:trip_ticket_filters][:trip_time]         ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:start] ||= nil
    params[:trip_ticket_filters][:trip_time][:end]   ||= nil
  end
end