class AddRateToTripClaim < ActiveRecord::Migration
  def change
    change_table :trip_claims do |t|
      t.text :rate
    end
    # Was previously a string, but text seems more appropriate
    change_table :services do |t|
      t.text :rate
    end
  end
end
