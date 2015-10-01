class AddRateToTripClaim < ActiveRecord::Migration
  def change
    change_table :trip_claims do |t|
      t.text :rate
    end
    # Was previously a string, but text seems more appropriate
    reversible do |dir|
      change_table :services do |t|
        dir.up   { t.change :rate, :text   }
        dir.down { t.change :rate, :string }
      end
    end
  end
end
