require 'reports/report'

module Reports
  class ProviderNewTripReport < Report

    attr_accessor :header, :rows, :summary

    def self.title
      "Provider New Trip Tickets Report"
    end

    def headers
      [['Submitted', 'Customer and Seats', 'Appointment Time', 'Pickup', 'Drop-off', 'Status']]
    end

    def initialize(user, options = {})
      trips = user.provider.trip_tickets.where(date_condition('trip_tickets.created_at', options)).order(:created_at)
      trips.each do |trip|
        create_data_row([
          "#{trip.created_at.strftime "%I:%M %p"} #{trip.created_at.strftime "%b %d"}",
          "#{trip.customer_full_name} #{trip.seats_required}",
          "#{trip.appointment_time.strftime "%I:%M %p"} #{trip.appointment_time.strftime "%b %d"}",
          trip.pick_up_location.try(:address_and_city, ', '),
          trip.drop_off_location.try(:address_and_city, ', '),
          trip.status_for(user)
        ])
      end
      @total = trips.length
    end

    def summary
      { "Total New Trip Tickets" => @total }
    end
  end
end