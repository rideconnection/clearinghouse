namespace :clearinghouse do
  namespace :trip_tickets do
    desc 'Expire trip tickets as necessary'
    task :expire => :environment do
      TripTicket.expire_tickets!
    end
  end
end