class CreateTripTicketComments < ActiveRecord::Migration
  def change
    create_table :trip_ticket_comments do |t|
      t.integer :trip_ticket_id
      t.integer :user_id
      t.text :body

      t.timestamps
    end
    add_index :trip_ticket_comments, :trip_ticket_id
  end
end
