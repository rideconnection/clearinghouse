require 'test_helper'

class TripTicketExpirationTest < ActiveSupport::TestCase
  describe "trip ticket expiration" do
    before do
      # 1st day of July 2012 was a Sunday, which corresponds to our test matrix
      @start_date = Date.parse("2012-07-01") # Sun, 01 Jul 2012
      @end_date   = Date.parse("2012-07-14") # Sun, 01 Jul 2012
      
      @provider = FactoryGirl.create(:provider)
      
      @t01 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-08 09:00"), requested_pickup_time: "08:30", expire_at: nil)
      @t02 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-08 12:00"), requested_pickup_time: "09:45", expire_at: Time.zone.parse("2012-07-07 14:00"))
      @t03 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-09 12:30"), requested_pickup_time: "11:30", expire_at: nil)
      @t04 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-09 11:00"), requested_pickup_time: "10:00", expire_at: Time.zone.parse("2012-07-02 12:00"))
      @t05 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-10 13:00"), requested_pickup_time: "12:00", expire_at: nil)
      @t06 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-10 08:00"), requested_pickup_time: "05:00", expire_at: Time.zone.parse("2012-07-01 02:45"))
      @t07 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-11 13:00"), requested_pickup_time: "12:00", expire_at: nil)
        @t07.rescind!
      @t08 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-11 08:00"), requested_pickup_time: "05:00", expire_at: Time.zone.parse("2012-07-01 02:45"))
        FactoryGirl.create(:trip_claim, trip_ticket_id: @t08.id).approve!
      # This one is kind of redundent since there can only be a result if it
      # has an approved claim (like @t08), or if it has an approved claim and
      # is later rescinded (like @t07).
      @t09 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-12 17:00"), requested_pickup_time: "16:00", expire_at: nil)
        FactoryGirl.create(:trip_claim, trip_ticket_id: @t09.id).approve!
        @t09.reload.rescind! # Creates a result of "Cancelled"
      @t10 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-12 12:00"), requested_pickup_time: "11:45", expire_at: nil)
      # Note the contrived pickup time that's later than the appointment time. It's an edge case test.
      @t11 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-13 12:00"), requested_pickup_time: "13:00", expire_at: Time.zone.parse("2012-07-10 04:00"))
      @t12 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-14 15:00"), requested_pickup_time: "14:45", expire_at: nil)
      # Another edge case, this time with an expiration date after the appointment date
      @t13 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-13 12:00"), requested_pickup_time: "11:00", expire_at: Time.zone.parse("2012-07-14 12:00"))
      @t14 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-16 14:00"), requested_pickup_time: "12:00", expire_at: nil)
      @t15 = FactoryGirl.create(:trip_ticket, origin_provider_id: @provider.id, appointment_time: Time.zone.parse("2012-07-17 12:00"), requested_pickup_time: "11:00", expire_at: nil)
    end
    
    test "expire_tickets! method rounds to nearest hour" do
      # Assumes provider doesn't have any default expiration attributes
      assert  ticket_expires_at(@t01, "2012-07-08", "08:00", "07:59", Date.parse("2012-07-08"))
      assert  ticket_expires_at(@t02, "2012-07-07", "14:00", "13:59", Date.parse("2012-07-07"))
      assert  ticket_expires_at(@t03, "2012-07-09", "11:00", "10:59", Date.parse("2012-07-09"))
      assert  ticket_expires_at(@t04, "2012-07-02", "12:00", "11:59", Date.parse("2012-07-02"))
      assert  ticket_expires_at(@t05, "2012-07-10", "12:00", "11:59", Date.parse("2012-07-10"))
      assert  ticket_expires_at(@t06, "2012-07-01", "02:00", "01:59", Date.parse("2012-07-01"))
      assert ticket_wont_expire(@t07)
      assert ticket_wont_expire(@t08)
      assert ticket_wont_expire(@t09)
      assert  ticket_expires_at(@t10, "2012-07-12", "11:00", "10:59", Date.parse("2012-07-12"))
      assert  ticket_expires_at(@t11, "2012-07-10", "04:00", "03:59", Date.parse("2012-07-10"))
      assert  ticket_expires_at(@t12, "2012-07-14", "14:00", "13:59", Date.parse("2012-07-14"))
      assert  ticket_expires_at(@t13, "2012-07-14", "12:00", "11:59", Date.parse("2012-07-14"))
      assert ticket_wont_expire(@t14)
      assert ticket_wont_expire(@t15)
    end
    
    test "provider with defaults of 0 days @ 1200" do
      @provider.update_attributes(trip_ticket_expiration_days_before: 0, trip_ticket_expiration_time_of_day: "12:00")
      
      assert  ticket_expires_at(@t01, "2012-07-08", "12:00")
      assert  ticket_expires_at(@t02, "2012-07-07", "14:00")
      assert  ticket_expires_at(@t03, "2012-07-09", "12:00")
      assert  ticket_expires_at(@t04, "2012-07-02", "12:00")
      assert  ticket_expires_at(@t05, "2012-07-10", "12:00")
      assert  ticket_expires_at(@t06, "2012-07-01", "02:00")
      assert ticket_wont_expire(@t07)
      assert ticket_wont_expire(@t08)
      assert ticket_wont_expire(@t09)
      assert  ticket_expires_at(@t10, "2012-07-12", "12:00")
      assert  ticket_expires_at(@t11, "2012-07-10", "04:00")
      assert  ticket_expires_at(@t12, "2012-07-14", "12:00")
      assert  ticket_expires_at(@t13, "2012-07-14", "12:00")
      assert ticket_wont_expire(@t14)
      assert ticket_wont_expire(@t15)
    end
    
    test "provider with defaults of 1 day @ 0800" do
      @provider.update_attributes(trip_ticket_expiration_days_before: 1, trip_ticket_expiration_time_of_day: "08:00")
      
      assert  ticket_expires_at(@t01, "2012-07-06", "08:00")
      assert  ticket_expires_at(@t02, "2012-07-07", "14:00")
      assert  ticket_expires_at(@t03, "2012-07-06", "08:00")
      assert  ticket_expires_at(@t04, "2012-07-02", "12:00")
      assert  ticket_expires_at(@t05, "2012-07-09", "08:00")
      assert  ticket_expires_at(@t06, "2012-07-01", "02:00")
      assert ticket_wont_expire(@t07)
      assert ticket_wont_expire(@t08)
      assert ticket_wont_expire(@t09)
      assert  ticket_expires_at(@t10, "2012-07-11", "08:00")
      assert  ticket_expires_at(@t11, "2012-07-10", "04:00")
      assert  ticket_expires_at(@t12, "2012-07-13", "08:00")
      assert  ticket_expires_at(@t13, "2012-07-14", "12:00")
      assert  ticket_expires_at(@t14, "2012-07-13", "08:00")
      assert ticket_wont_expire(@t15)
    end
    
    test "provider with defaults of 7 days @ 1500" do
      @provider.update_attributes(trip_ticket_expiration_days_before: 7, trip_ticket_expiration_time_of_day: "15:00")
      
      # Tickets 1, 3, & 5 should expire prior to July 1
      assert  ticket_expires_at(@t01, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t02, "2012-07-07", "14:00")
      assert  ticket_expires_at(@t03, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t04, "2012-07-02", "12:00")
      assert  ticket_expires_at(@t05, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t06, "2012-07-01", "02:00")
      assert ticket_wont_expire(@t07)
      assert ticket_wont_expire(@t08)
      assert ticket_wont_expire(@t09)
      assert  ticket_expires_at(@t10, "2012-07-03", "15:00")
      assert  ticket_expires_at(@t11, "2012-07-10", "04:00")
      assert  ticket_expires_at(@t12, "2012-07-05", "15:00")
      assert  ticket_expires_at(@t13, "2012-07-14", "12:00")
      assert  ticket_expires_at(@t14, "2012-07-05", "15:00")
      assert  ticket_expires_at(@t15, "2012-07-06", "15:00")
    end
    
    test "provider with defaults of 10 days @ 0100" do
      @provider.update_attributes(trip_ticket_expiration_days_before: 10, trip_ticket_expiration_time_of_day: "01:00")
      
      # Tickets 1, 3, 5, & 10 should expire prior to July 1
      assert  ticket_expires_at(@t01, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t02, "2012-07-07", "14:00")
      assert  ticket_expires_at(@t03, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t04, "2012-07-02", "12:00")
      assert  ticket_expires_at(@t05, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t06, "2012-07-01", "02:00")
      assert ticket_wont_expire(@t07)
      assert ticket_wont_expire(@t08)
      assert ticket_wont_expire(@t09)
      assert  ticket_expires_at(@t10, "2012-06-30", "23:00", "23:00")
      assert  ticket_expires_at(@t11, "2012-07-10", "04:00")
      assert  ticket_expires_at(@t12, "2012-07-02", "01:00")
      assert  ticket_expires_at(@t13, "2012-07-14", "12:00")
      assert  ticket_expires_at(@t14, "2012-07-02", "01:00")
      assert  ticket_expires_at(@t15, "2012-07-03", "01:00")
    end
  end
  
  def ticket_expires_at(ticket, expiration_date, expiration_time, start_time = nil, start_date = nil, end_date = @end_date)
    # In most cases we can just test that one hour before the ticket should 
    # expire it is NOT expired, then advance one hour and test to make sure
    # it IS expired.
    start_date ||= Date.parse(expiration_date)
    start_time ||= "#{expiration_time.to_i - 1}:00"
    
    # Rails.logger.debug "- Testing ticket #{ticket.to_param}"
    expected_expiration = Time.zone.parse("#{expiration_date} #{expiration_time}")
    # Rails.logger.debug "-- Expected expiration = #{expected_expiration}"
    (start_date..end_date).each do |date|
      # Rails.logger.debug "-- Testing date: #{date}"
      (start_time.to_i..23).each_with_index do |hour,index|
        runtime = Time.zone.parse("#{date} #{start_time}") + index.hours
        # Rails.logger.debug "--- Testing time: #{runtime.strftime("%H:%M %Z %z")}"
        Timecop.freeze(runtime) do
          TripTicket.expire_tickets!          
          if runtime.change(min: 0) == expected_expiration.change(min: 0)
             # Did the ticket expire when we expected it to?
             # Rails.logger.debug "---- Checking to see if the ticket expired as expected"
             return cleanup_from_ticket_expiration_test_and_return ticket.reload.expired?
          elsif runtime.change(min: 0) <= expected_expiration.change(min: 0) && ticket.reload.expired?
            # The ticket expired too early
            # Rails.logger.debug "---- The ticket expired too early"
            return cleanup_from_ticket_expiration_test_and_return false
          end
        end # Timecop
      end # hour
    end # date
    
    # As a last resort
    # Rails.logger.debug "-- Exiting w/o ticket having been expired"
    return cleanup_from_ticket_expiration_test_and_return false
  end
  
  def ticket_wont_expire(ticket)
    return !ticket_expires_at(ticket, @end_date.to_s, "23:00", "23:00", @end_date, @end_date)
  end
  
  def cleanup_from_ticket_expiration_test_and_return(return_value)
    # Rails.logger.debug "- Resetting all trip ticket expired flags for next test"
    # Reset all expiration flags so subsequent calls will work
    TripTicket.unscoped.update_all(expired: false)

    return return_value
  end
end
