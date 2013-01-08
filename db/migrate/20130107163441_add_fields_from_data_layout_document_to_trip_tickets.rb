class AddFieldsFromDataLayoutDocumentToTripTickets < ActiveRecord::Migration
  def change
    add_column :trip_tickets, :customer_primary_language, :string
    add_column :trip_tickets, :customer_first_name, :string
    add_column :trip_tickets, :customer_last_name, :string
    add_column :trip_tickets, :customer_middle_name, :string
    add_column :trip_tickets, :requested_pickup_time, :time
    add_column :trip_tickets, :requested_drop_off_time, :time
    add_column :trip_tickets, :customer_ethnicity_id, :integer
  end
end
