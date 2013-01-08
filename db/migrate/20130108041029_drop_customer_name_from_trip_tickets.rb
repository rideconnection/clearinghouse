class DropCustomerNameFromTripTickets < ActiveRecord::Migration
  def up
    transaction do
      TripTicket.all.each do |t|
        unless t.customer_name.blank? || (!t.customer_first_name.blank? && !t.customer_middle_name.blank? && !t.customer_last_name.blank?)
          t.customer_first_name, t.customer_last_name = t.customer_name.split(" ")
          t.save!
        end
      end
      
      remove_column :trip_tickets, :customer_name
    end
  end

  def down
    transaction do
      add_column :trip_tickets, :customer_name, :string

      TripTicket.all.each do |t|
        t.customer_name = [t.customer_first_name, t.customer_middle_name, t.customer_last_name].compact.join(" ")
        t.save!
      end
    end    
  end
end