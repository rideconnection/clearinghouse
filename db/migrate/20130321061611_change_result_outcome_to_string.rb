class ChangeResultOutcomeToString < ActiveRecord::Migration
  def up
    change_column :trip_results, :outcome, :string
  end

  def down
    change_column :trip_results, :outcome, :integer
  end
end
