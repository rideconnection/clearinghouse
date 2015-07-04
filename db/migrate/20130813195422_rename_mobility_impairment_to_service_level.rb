class RenameMobilityImpairmentToServiceLevel < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :customer_service_level, :string
    execute "UPDATE trip_tickets SET customer_service_level = array_to_string(customer_mobility_impairments, ',')"
    add_index :trip_tickets, [:customer_service_level], :name => "customer_service_level"
    remove_index :trip_tickets, name: :customer_mobility_impairments
    remove_column :trip_tickets, :customer_mobility_impairments
  end

  def down
    add_column :trip_tickets, :customer_mobility_impairments, :string, array: true
    execute "UPDATE trip_tickets SET customer_mobility_impairments = string_to_array(customer_service_level, ',')"
    execute "CREATE INDEX customer_mobility_impairments ON trip_tickets USING GIN(customer_mobility_impairments)"
    remove_index :trip_tickets, :name => "customer_service_level"
    remove_column :trip_tickets, :customer_service_level
  end
end
