class ChangedTripRescindedColumn < ActiveRecord::Migration
  def change
    change_column :trip_tickets, :rescinded, :boolean, :null => false, :default => false
  end
end
