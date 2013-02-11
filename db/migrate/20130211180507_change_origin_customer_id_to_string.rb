class ChangeOriginCustomerIdToString < ActiveRecord::Migration
  def up
    change_column :trip_tickets, :origin_customer_id, :string
  end

  def down
    connection.execute(%q{
      ALTER TABLE trip_tickets
      ALTER COLUMN origin_customer_id
      TYPE integer USING CAST(origin_customer_id AS integer)
    })
  end
end