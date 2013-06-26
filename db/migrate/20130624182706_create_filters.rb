class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.integer :user_id
      t.string :name
      t.text :data

      t.timestamps
    end
  end
end
