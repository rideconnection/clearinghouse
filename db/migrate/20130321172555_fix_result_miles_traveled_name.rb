class FixResultMilesTraveledName < ActiveRecord::Migration
  def change
    rename_column :trip_results, :miles_travelled, :miles_traveled
  end
end
