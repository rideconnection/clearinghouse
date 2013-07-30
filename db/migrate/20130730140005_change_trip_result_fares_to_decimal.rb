class ChangeTripResultFaresToDecimal < ActiveRecord::Migration
  def up
    change_column :trip_results, :rate, :decimal, :precision => 10, :scale => 2
    change_column :trip_results, :fare, :decimal, :precision => 10, :scale => 2
    change_column :trip_results, :base_fare, :decimal, :precision => 10, :scale => 2
  end

  def down
    change_column :trip_results, :rate, :integer
    change_column :trip_results, :fare, :integer
    change_column :trip_results, :base_fare, :integer
  end
end
