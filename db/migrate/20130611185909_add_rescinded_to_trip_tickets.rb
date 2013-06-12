class AddRescindedToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :rescinded, :boolean
  end
end
