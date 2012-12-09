class AddForeignKeysToLocation < ActiveRecord::Migration
  def change
    change_table(:locations) do |t|
      t.integer :addressable_id
      t.string :addressable_type
    end
  end
end
