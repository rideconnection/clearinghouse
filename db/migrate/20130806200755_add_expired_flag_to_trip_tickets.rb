class AddExpiredFlagToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :expired, :boolean, :default => false
    add_index :trip_tickets, :expired
    rename_column :trip_tickets, :expires_at, :expire_at
  end
end