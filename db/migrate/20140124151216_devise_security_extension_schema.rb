class DeviseSecurityExtensionSchema < ActiveRecord::Migration
  def up
    add_column :users, :password_changed_at, :datetime
    add_index :users, :password_changed_at
    
    create_table :old_passwords do |t|
      t.string :encrypted_password, :null => false
      t.string :password_salt
      t.string :password_archivable_type, :null => false
      t.integer :password_archivable_id, :null => false
      t.datetime :created_at
    end
    add_index :old_passwords, [:password_archivable_type, :password_archivable_id], :name => :index_password_archivable
  end

  def down
    drop_table :old_passwords
    remove_index :users, :password_changed_at
    remove_column :users, :password_changed_at
  end
end