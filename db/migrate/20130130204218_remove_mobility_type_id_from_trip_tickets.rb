class RemoveMobilityTypeIdFromTripTickets < ActiveRecord::Migration
  def up
    remove_column :trip_tickets, :mobility_type_id
  end

  def down
    add_column :trip_tickets, :mobility_type_id, :integer
  end
end
