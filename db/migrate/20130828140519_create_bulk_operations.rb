class CreateBulkOperations < ActiveRecord::Migration
  def change
    create_table :bulk_operations do |t|
      t.integer :user_id
      t.boolean :completed, default: false
      t.integer :row_count
      t.string :file_name
      t.datetime :last_exported_timestamp
      t.boolean :is_upload, default: false
      t.integer :error_count
      t.string :row_errors, array: true
      t.text :data
      t.timestamps
    end
  end
end
