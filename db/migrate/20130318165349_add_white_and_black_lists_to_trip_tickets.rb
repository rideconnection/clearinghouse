class AddWhiteAndBlackListsToTripTickets < ActiveRecord::Migration
  def up
    add_column :trip_tickets, :provider_white_list, :integer_array
    add_column :trip_tickets, :provider_black_list, :integer_array
    execute "CREATE INDEX provider_white_list ON trip_tickets USING GIN(provider_white_list)"
    execute "CREATE INDEX provider_black_list ON trip_tickets USING GIN(provider_black_list)"
  end
  
  def down
    execute "DROP INDEX provider_black_list"
    execute "DROP INDEX provider_white_list"
    remove_column :trip_tickets, :provider_black_list
    remove_column :trip_tickets, :provider_white_list
  end
end
