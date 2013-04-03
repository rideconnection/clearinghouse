class SetDefaultTripTicketAppointmentTime < ActiveRecord::Migration
  def up
    TripTicket.all.each do |tt|
      if tt.appointment_time.blank?
        tt.appointment_time = tt.created_at
        tt.save
      end
    end
  end

  def down
  end
end
