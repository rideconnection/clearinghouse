class AddTripFundersToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :trip_funders, :string, array: true
    execute "CREATE INDEX trip_funders ON trip_tickets USING GIN(trip_funders)"
  end

  def down
    execute "DROP INDEX trip_funders"
    remove_column :trip_tickets, :trip_funders
  end
end
