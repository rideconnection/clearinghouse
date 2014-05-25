class AddExpirationDateTimeToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :expires_at, :datetime
  end
end
