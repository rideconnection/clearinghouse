class AddCustomerServiceAnimalsToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :customer_service_animals, :string, array: true
    execute "CREATE INDEX customer_service_animals ON trip_tickets USING GIN(customer_service_animals)"
  end

  def down
    execute "DROP INDEX customer_service_animals"
    remove_column :trip_tickets, :customer_service_animals
  end
end
