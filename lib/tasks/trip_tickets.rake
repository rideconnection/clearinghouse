namespace :clearinghouse do
  namespace :trip_tickets do
    desc 'Expire trip tickets as necessary'
    task :expire => :environment do
      puts "Calling TripTicket.expire_tickets! with threshold #{Time.zone.now.to_s :rfc822}"
      TripTicket.expire_tickets! Logger.new(STDOUT)
      puts "Completed expiring tickets"
    end
  end
end