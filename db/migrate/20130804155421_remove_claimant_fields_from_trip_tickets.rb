class RemoveClaimantFieldsFromTripTickets < ActiveRecord::Migration
  def up
    remove_column :trip_tickets, :claimant_provider_id
    remove_column :trip_tickets, :claimant_trip_id
  end

  def down
    add_column :trip_tickets, :claimant_provider_id, :integer
    add_column :trip_tickets, :claimant_trip_id, :integer
  end
end
