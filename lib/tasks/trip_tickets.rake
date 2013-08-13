namespace :clearinghouse do
  namespace :trip_tickets do
    desc 'Expire trip tickets as necessary'
    task :expire => :environment do
      puts "Preparing to expire tickets #{Time.current.to_datetime.in_time_zone}"
      TripTicket.expire_tickets!
      puts "Completed expiring tickets"
    end
  end
end