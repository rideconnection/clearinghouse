class CreateProviderRelationships < ActiveRecord::Migration
  def change
    create_table :provider_relationships do |t|
      t.integer :requesting_provider_id
      t.integer :cooperating_provider_id
      t.date :approved_at
      t.boolean :automatic_requester_approval
      t.boolean :automatic_cooperator_approval

      t.timestamps
    end
  end
end
