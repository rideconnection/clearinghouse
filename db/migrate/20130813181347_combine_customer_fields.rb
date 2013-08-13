class CombineCustomerFields < ActiveRecord::Migration
  def up
    # combine 'guest' array values with normal arrays
    execute "UPDATE trip_tickets SET customer_service_animals = customer_service_animals || guest_or_attendant_service_animals"
    execute "UPDATE trip_tickets SET customer_assistive_devices = customer_assistive_devices || guest_or_attendant_assistive_devices"

    # drop guest arrays and related indexes
    remove_index :trip_tickets, name: :guest_or_attendant_service_animals
    remove_index :trip_tickets, name: :guest_or_attendant_assistive_devices
    remove_column :trip_tickets, :guest_or_attendant_service_animals
    remove_column :trip_tickets, :guest_or_attendant_assistive_devices

    # rename customer_assistive_devices column per task #1637
    remove_index :trip_tickets, name: :customer_assistive_devices
    rename_column :trip_tickets, :customer_assistive_devices, :customer_mobility_factors
    execute "CREATE INDEX customer_mobility_factors ON trip_tickets USING GIN(customer_mobility_factors)"

    # remove eligibility rules that use guest_or_attendant_* (irreversible)
    execute "DELETE FROM eligibility_rules WHERE trip_field IN ('guest_or_attendant_service_animals', 'guest_or_attendant_assistive_devices')"

    # update eligibility rules that use customer_assistive_devices
    execute "UPDATE eligibility_rules SET trip_field = 'customer_mobility_factors' WHERE trip_field = 'customer_assistive_devices'"
  end

  def down
    execute "UPDATE eligibility_rules SET trip_field = 'customer_assistive_devices' WHERE trip_field = 'customer_mobility_factors'"

    remove_index :trip_tickets, name: :customer_mobility_factors
    rename_column :trip_tickets, :customer_mobility_factors, :customer_assistive_devices
    execute "CREATE INDEX customer_assistive_devices ON trip_tickets USING GIN(customer_assistive_devices)"

    add_column :trip_tickets, :guest_or_attendant_service_animals, :string_array
    add_column :trip_tickets, :guest_or_attendant_assistive_devices, :string_array
    execute "CREATE INDEX guest_or_attendant_service_animals ON trip_tickets USING GIN(guest_or_attendant_service_animals)"
    execute "CREATE INDEX guest_or_attendant_assistive_devices ON trip_tickets USING GIN(guest_or_attendant_assistive_devices)"
  end
end
