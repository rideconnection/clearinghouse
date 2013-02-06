class UpdateTripClaimsAndTripTicketsFields < ActiveRecord::Migration
  def change 
    remove_column :trip_tickets, :claimant_customer_id
    remove_column :trip_tickets, :approved_claim_id
    remove_column :trip_purpose_code

    add_column :trip_claims, :claimant_customer_id, :integer
    add_column :trip_claims, :claimant_trip_id, :integer

    # Remove old time fields and re-add as datetime fields, so rails can 
    # automatically reverse migration
    remove_column :trip_tickets, :earliest_pick_up_time
    remove_column :trip_tickets, :appointment_time
    add_column :trip_tickets, :earliest_pick_up_time, :datetime
    add_column :trip_tickets, :appointment_time, :datetime
  end
end
