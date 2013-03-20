module TripTicketsFilter

  def trip_tickets_filter(collection)
    collection ||= TripTicket.all
    init_trip_ticket_trip_time_filter_values

    params[:trip_ticket_filters].try(:each) do |filter, value|
      case filter.to_sym
      when :seats_required
        collection = collection.filter_by_seats_required(value) unless value.try(:[], "min").blank? && value.try(:[], "max").blank?
      when :trip_time
        unless (
          value[:start].try(:[], :month).blank? && value[:start].try(:[], :day).blank? && value[:start].try(:[], :year).blank? &&
          value[:start].try(:[], :hour).blank? && value[:start].try(:[], :minute).blank? &&
          value[:end].try(:[], :month).blank? && value[:end].try(:[], :day).blank? && value[:end].try(:[], :year).blank? &&
          value[:start].try(:[], :end).blank? && value[:end].try(:[], :minute).blank?
        )
          collection = collection.filter_by_trip_time(
            parse_trip_ticket_trip_time(value[:start], Time.zone.at(0)),
            parse_trip_ticket_trip_time(value[:end], Time.zone.at(9_999_999_999))
          )
        end
      else
        if !value.blank? && TripTicket.respond_to?("filter_by_#{filter.to_s}")
          collection = collection.send("filter_by_#{filter.to_s}", value)
        end
      end
    end

    collection
  end

  private

  def parse_trip_ticket_trip_time(datetime_array, default)
    begin; Time.zone.parse("#{datetime_array[:year].to_i}-#{datetime_array[:month].to_i}-#{datetime_array[:day].to_i} #{datetime_array[:hour].to_i}:#{datetime_array[:minute].to_i}"); rescue; default; end
  end

  def init_trip_ticket_trip_time_filter_values
    params[:trip_ticket_filters]                     ||= Hash.new
    params[:trip_ticket_filters][:trip_time]         ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:start] ||= Hash.new
    params[:trip_ticket_filters][:trip_time][:end]   ||= Hash.new
  end
end