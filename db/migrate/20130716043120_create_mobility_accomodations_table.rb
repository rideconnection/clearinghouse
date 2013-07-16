class CreateMobilityAccomodationsTable < ActiveRecord::Migration
  def change
    create_table :mobility_accomodations do |t|
      t.integer :provider_id
      t.string :mobility_impairment
      t.timestamps
    end
    add_index :mobility_accomodations, :provider_id
  end
end
