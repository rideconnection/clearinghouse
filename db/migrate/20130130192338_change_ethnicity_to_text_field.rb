class ChangeEthnicityToTextField < ActiveRecord::Migration
  def up
    drop_table :ethnicities
    remove_column :trip_tickets, :customer_ethnicity_id 
    add_column :trip_tickets, :customer_ethnicity, :string
  end

  def down
    create_table "ethnicities" do |t|
      t.string   "name"
      t.timestamps
    end

    add_column :trip_tickets, :customer_ethnicity_id, :integer
    remove_column :trip_tickets, :customer_ethnicity
  end
end
