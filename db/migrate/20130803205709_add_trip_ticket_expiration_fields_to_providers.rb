class AddTripTicketExpirationFieldsToProviders < ActiveRecord::Migration
  def change
    add_column :providers, :trip_ticket_expiration_days_before, :integer
    add_column :providers, :trip_ticket_expiration_time_of_day, :time
  end
end
