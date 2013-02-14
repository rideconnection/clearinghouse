class RemoveCompoundIndexFromProviderRelationships < ActiveRecord::Migration
  def up
    remove_index :provider_relationships, :name => "index_provider_relationships_on_requesting_provider_id_and_coo"
  end

  def down
    add_index :provider_relationships, [:requesting_provider_id, :cooperating_provider_id], :name => "index_provider_relationships_on_requesting_provider_id_and_coo", :unique => true
  end
end