class AddCustomerEligibilityFactorsToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :customer_eligibility_factors, :string, array: true
    execute "CREATE INDEX customer_eligibility_factors ON trip_tickets USING GIN(customer_eligibility_factors)"
  end

  def down
    execute "DROP INDEX customer_eligibility_factors"
    remove_column :trip_tickets, :customer_eligibility_factors
  end
end
