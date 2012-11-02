class ChangeSecurementsToCount < ActiveRecord::Migration
  def up
    remove_column :trip_results, :extra_securements_used
    add_column :trip_results, :extra_securement_count, :integer
  end

  def down
    add_column :trip_results, :extra_securements_used, :string
    remove_column :trip_results, :extra_securement_count
  end
end
