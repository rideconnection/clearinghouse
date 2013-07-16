class CreateMobilityAccommodationsTable < ActiveRecord::Migration
  def change
    create_table :mobility_accommodations do |t|
      t.integer :provider_id
      t.string :mobility_impairment
      t.timestamps
    end
    add_index :mobility_accommodations, :provider_id
  end
end
