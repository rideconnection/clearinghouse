class ChangeDriverIdToString < ActiveRecord::Migration
  def up
    change_column :trip_results, :driver_id, :string
  end

  def down
    change_column :trip_results, :driver_id, :integer
  end
end
