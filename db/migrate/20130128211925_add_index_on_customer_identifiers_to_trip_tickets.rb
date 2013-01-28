class AddIndexOnCustomerIdentifiersToTripTickets < ActiveRecord::Migration
  def up
    execute "CREATE INDEX customer_identifiers ON trip_tickets USING GIN(customer_identifiers)"
  end

  def down
    execute "DROP INDEX customer_identifiers"
  end
end
