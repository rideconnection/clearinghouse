class ChangeSchedulingPriorityDatatypeInTripTickets < ActiveRecord::Migration
  def up
    change_column :trip_tickets, :scheduling_priority, :string
  end

  def down
    change_column :trip_tickets, :scheduling_priority, :integer
  end
end