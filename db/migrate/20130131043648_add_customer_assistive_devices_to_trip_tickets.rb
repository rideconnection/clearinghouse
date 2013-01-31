class AddCustomerAssistiveDevicesToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :customer_assistive_devices, :string_array
    execute "CREATE INDEX customer_assistive_devices ON trip_tickets USING GIN(customer_assistive_devices)"
  end

  def down
    execute "DROP INDEX customer_assistive_devices"
    remove_column :trip_tickets, :customer_assistive_devices
  end
end
