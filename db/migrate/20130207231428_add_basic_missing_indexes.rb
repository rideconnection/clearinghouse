class AddBasicMissingIndexes < ActiveRecord::Migration
  def change
    add_index :trip_tickets, :origin_provider_id
    add_index :trip_claims, :trip_ticket_id
    add_index :trip_claims, :claimant_provider_id
    add_index :users, :provider_id
    add_index :locations, [:addressable_id, :addressable_type]
    add_index :nonces, :provider_id
    add_index :nonces, :created_at
    add_index :open_capacities, :service_id
    add_index :operating_hours, :service_id
    add_index :provider_relationships, :requesting_provider_id
    add_index :provider_relationships, :cooperating_provider_id
    add_index :provider_relationships, [:requesting_provider_id, :cooperating_provider_id], :unique => true, :name => "index_provider_relationships_on_requesting_provider_id_and_coo"
    add_index :roles, :name
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
    add_index :roles_users, [:role_id, :user_id], :unique => true
    add_index :service_requests, :trip_ticket_id
    add_index :services, :provider_id
    add_index :trip_results, :trip_ticket_id
  end
end