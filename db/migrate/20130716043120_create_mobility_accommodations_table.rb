class CreateMobilityAccommodationsTable < ActiveRecord::Migration
  def change
    create_table :mobility_accommodations do |t|
      t.integer :service_id
      t.string :mobility_impairment
      t.timestamps
    end
    add_index :mobility_accommodations, :service_id
  end
end
