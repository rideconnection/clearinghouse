class CreateBulkOperations < ActiveRecord::Migration
  def change
    create_table :bulk_operations do |t|
      t.integer :user_id
      t.integer :row_count
      t.datetime :last_import_time
      t.boolean :is_upload, default: false
      t.string :file_name
      t.integer :error_count
      t.integer_array :bad_row_numbers
      t.text :data
      t.timestamps
    end
  end
end
