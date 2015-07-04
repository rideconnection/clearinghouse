class AddGuestOrAttendantAssistiveDevicesToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :guest_or_attendant_assistive_devices, :string, array: true
    execute "CREATE INDEX guest_or_attendant_assistive_devices ON trip_tickets USING GIN(guest_or_attendant_assistive_devices)"
  end

  def down
    execute "DROP INDEX guest_or_attendant_assistive_devices"
    remove_column :trip_tickets, :guest_or_attendant_assistive_devices
  end
end
