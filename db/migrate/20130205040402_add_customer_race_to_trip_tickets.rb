class AddCustomerRaceToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :customer_race, :string
  end
end
