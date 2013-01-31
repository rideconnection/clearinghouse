class IndexCustomerMobilityImpairmentsOnTripTickets < ActiveRecord::Migration
  def up
    execute "CREATE INDEX customer_mobility_impairments ON trip_tickets USING GIN(customer_mobility_impairments)"
  end

  def down
    execute "DROP INDEX customer_mobility_impairments"
  end
end
