class AddMobilityTypeToTicket < ActiveRecord::Migration
  def change
    create_table :mobility_types do |t|
      t.string :name
      t.string :description
    end

    add_column :trip_tickets, :mobility_type_id, :integer
  end
end
