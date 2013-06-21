module TripTicketsFilter

  def trip_tickets_filter(collection)
    collection ||= TripTicket.all
    init_trip_ticket_trip_time_filter_values

    # apply rescinded filter at the end so we can apply default if not specified
    rescinded_filter = nil

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
      else
        if !value.blank? && TripTicket.respond_to?("filter_by_#{filter.to_s}")
          collection = collection.send("filter_by_#{filter.to_s}", value)
        end
      end
    end

    # expects 'include_rescinded', 'only_rescinded', or 'exclude_rescinded'/nil (default)
    # 'include_rescinded' basically means to not filter so does nothing
    collection = collection.filter_by_rescinded(rescinded_filter) unless rescinded_filter == 'include_rescinded'

    collection
  end

  def parse_trip_ticket_trip_time(datetime_value, default)
    Time.zone.parse(datetime_value) rescue default
  end

  private

  def init_trip_ticket_trip_time_filter_values
    params[:trip_ticket_filters]                     ||= Hash.new
    params[:trip_ticket_filters][:trip_time]         ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:start] ||= nil
    params[:trip_ticket_filters][:trip_time][:end]   ||= nil

    params[:trip_ticket_filters][:trip_time][:start] ||= nil
    params[:trip_ticket_filters][:trip_time][:end]   ||= nil
  end
end