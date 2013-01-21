class RemoveRateFieldFromTripClaims < ActiveRecord::Migration
  def up
    remove_column :trip_claims, :rate
  end

  def down
    add_column :trip_claims, :rate, :string
  end
end
