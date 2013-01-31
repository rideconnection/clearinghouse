class AddGuestOrAttendantServiceAnimalsToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :guest_or_attendant_service_animals, :string_array
    execute "CREATE INDEX guest_or_attendant_service_animals ON trip_tickets USING GIN(guest_or_attendant_service_animals)"
  end

  def down
    execute "DROP INDEX guest_or_attendant_service_animals"
    remove_column :trip_tickets, :guest_or_attendant_service_animals
  end
end
