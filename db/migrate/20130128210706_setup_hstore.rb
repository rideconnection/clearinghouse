class SetupHstore < ActiveRecord::Migration

  # Removing original migration code since (a) the extension should already be 
  # activated and (b) the "CREATE EXTENSION" is not supported in Postgres 8.4 environments.

  def self.up
    #execute "CREATE EXTENSION IF NOT EXISTS hstore"
  end

  def self.down
    #execute "DROP EXTENSION IF EXISTS hstore"
  end
end
