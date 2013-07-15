class CreateEligibilityRequirementTables < ActiveRecord::Migration
  def change
    create_table :requirement_sets do |t|
      t.integer :provider_id
      t.string :boolean_type
      t.timestamps
    end
    create_table :eligibility_requirements do |t|
      t.integer :requirement_set_id
      t.string :trip_field
      t.string :comparison_type
      t.string :comparison_value
      t.timestamps
    end
    add_index :eligibility_requirements, :requirement_set_id
  end
end
