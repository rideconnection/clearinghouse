class RemoveOriginProviderIdFromTripClaims < ActiveRecord::Migration
  def up
    remove_column :trip_claims, :origin_provider_id
  end

  def down
    add_column :trip_claims, :origin_provider_id, :integer
  end
end