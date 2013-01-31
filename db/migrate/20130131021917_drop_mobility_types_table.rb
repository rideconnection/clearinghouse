class DropMobilityTypesTable < ActiveRecord::Migration
  def up
    drop_table :mobility_types
  end

  def down
    create_table "mobility_types" do |t|
      t.string "name"
      t.string "description"
      t.timestamps
    end
  end
end
