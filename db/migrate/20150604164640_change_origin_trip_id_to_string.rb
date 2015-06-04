class ChangeOriginTripIdToString < ActiveRecord::Migration
  def up
    change_column :trip_tickets, :origin_trip_id, :string
  end

  def down
    change_column :trip_tickets, :origin_trip_id, :integer
  end
end
