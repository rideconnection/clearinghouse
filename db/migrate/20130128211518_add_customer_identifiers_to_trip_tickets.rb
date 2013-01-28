class AddCustomerIdentifiersToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :customer_identifiers, :hstore
  end
end
