class DropMobilityAccommodations < ActiveRecord::Migration
  def up
    drop_table :mobility_accommodations
  end

  def down
    create_table :mobility_accommodations do |t|
      t.integer :service_id
      t.string :mobility_impairment
      t.timestamps
    end
    add_index :mobility_accommodations, :service_id
  end
end
