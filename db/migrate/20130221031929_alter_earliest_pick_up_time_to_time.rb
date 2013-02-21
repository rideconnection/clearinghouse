class AlterEarliestPickUpTimeToTime < ActiveRecord::Migration
  def up
    change_column :trip_tickets, :earliest_pick_up_time, :time
  end

  def down
    connection.execute(%q{
      ALTER TABLE "trip_tickets"
      ALTER COLUMN "earliest_pick_up_time"
      TYPE timestamp without time zone USING to_timestamp(CONCAT(CAST(DATE(appointment_time) as character varying(255)), ' ', CAST(earliest_pick_up_time as character varying(255))), 'YYYY-MM-DD HH24:MI:SS.US')
    })
  end
end