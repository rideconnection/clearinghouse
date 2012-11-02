class AddClaimantServiceIdToTripClaims < ActiveRecord::Migration
  def change
    change_table :trip_claims do |t|
      t.integer :claimant_service_id
    end
  end
end
