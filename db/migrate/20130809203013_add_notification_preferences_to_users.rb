class AddNotificationPreferencesToUsers < ActiveRecord::Migration

  def up
    add_column :users, :notification_preferences, :string_array
    execute "CREATE INDEX notification_preferences_index ON users USING GIN(notification_preferences)"
  end

  def down
    execute "DROP INDEX notification_preferences_index"
    remove_column :users, :notification_preferences
  end
end
