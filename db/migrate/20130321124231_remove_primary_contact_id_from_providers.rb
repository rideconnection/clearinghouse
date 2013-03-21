class RemovePrimaryContactIdFromProviders < ActiveRecord::Migration
  def up
    remove_column :providers, :primary_contact_id
  end

  def down
    add_column :providers, :primary_contact_id, :integer
  end
end