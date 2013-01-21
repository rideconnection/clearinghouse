class AddProposedFieldsToTripClaims < ActiveRecord::Migration
  def change
    add_column :trip_claims, :proposed_pickup_time, :datetime
    add_column :trip_claims, :proposed_fare, :string
    add_column :trip_claims, :notes, :text
  end
end
