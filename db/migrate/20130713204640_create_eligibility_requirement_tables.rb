class CreateEligibilityRequirementTables < ActiveRecord::Migration
  def change
    create_table :eligibility_requirements do |t|
      t.integer :provider_id
      t.string :boolean_type
      t.timestamps
    end
    create_table :eligibility_rules do |t|
      t.integer :eligibility_requirement_id
      t.string :trip_field
      t.string :comparison_type
      t.string :comparison_value
      t.timestamps
    end
    add_index :eligibility_requirements, :provider_id
    add_index :eligibility_rules, :eligibility_requirement_id
  end
end
