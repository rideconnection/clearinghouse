class ClearinghouseFieldAdditions < ActiveRecord::Migration
  def up
    # Customer sex
    add_column :trip_tickets, :customer_gender, :string, limit: 1

    # Estimated trip distance (in miles)
    add_column :trip_tickets, :estimated_distance, :integer

    # Replace allowed_time_variance with time window before and time window after fields
    add_column :trip_tickets, :time_window_before, :integer
    add_column :trip_tickets, :time_window_after, :integer
    TripTicket.where('allowed_time_variance IS NOT NULL').update_all('time_window_before = allowed_time_variance, time_window_after = allowed_time_variance')
    remove_column :trip_tickets, :allowed_time_variance

    # Free-form literal input record for API access only.
    add_column :trip_tickets, :additional_data, :hstore

    # Address phone number
    add_column :locations, :phone_number, :string

    # Address common name
    add_column :locations, :common_name, :string

    # Address jurisdiction (county/parish/borough)
    add_column :locations, :jurisdiction, :string

    # Trip Results - Notes
    add_column :trip_results, :notes, :text
  end

  def down
    remove_column :trip_tickets, :customer_gender
    remove_column :trip_tickets, :estimated_distance
    add_column :trip_tickets, :allowed_time_variance, :integer
    TripTicket.where('time_window_before IS NOT NULL OR time_window_after IS NOT NULL').update_all('allowed_time_variance = LEAST(COALESCE(time_window_before, 0), COALESCE(time_window_after, 0))')
    remove_column :trip_tickets, :time_window_before
    remove_column :trip_tickets, :time_window_after
    remove_column :trip_tickets, :additional_data
    remove_column :locations, :phone_number
    remove_column :locations, :common_name
    remove_column :locations, :jurisdiction
    remove_column :trip_results, :notes
  end
end
