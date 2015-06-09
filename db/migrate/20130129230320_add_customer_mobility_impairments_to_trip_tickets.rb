class AddCustomerMobilityImpairmentsToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :customer_mobility_impairments, :string, array: true
  end
end
