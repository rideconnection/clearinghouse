namespace :clearinghouse do
  namespace :trip_tickets do
    desc 'Expire trip tickets as necessary'
    task :expire => :environment do
      puts "Calling TripTicket.expire_tickets! with threshold #{Time.zone.now.to_s :rfc822}"
      TripTicket.expire_tickets! Logger.new(STDOUT)
      puts "Completed expiring tickets"
    end

    namespace :development do
      desc "Run all clearinghouse:trip_tickets:development tasks"
      task :reset => ["clearinghouse:trip_tickets:development:unrescind", "clearinghouse:trip_tickets:development:unexpire", "clearinghouse:trip_tickets:development:rebase_appointment_and_expiration_dates"]

      desc 'Reset the rescinded flag, or pass in an ID to reset a single ticket. Ex: `rake clearinghouse:trip_tickets:development:unrescind[123]`'
      task :unrescind, [:id] => [:environment] do |t, args|
        args.with_defaults(:id => nil)
        tickets = TripTicket.where(rescinded: true)
        tickets = tickets.where(id: args.id) if args.id.to_i > 0
        TripTicket.transaction do
          # `each` is expensive, but we want to ensure an audit log is generated
          # and validations are ignored
          tickets.find_each do |tt|
            puts "Preparing to unrescind ticket ##{tt.id}"
            tt.rescinded = false
            tt.save(validate: false)
            tt.trip_claims.where(status: 'rescinded').find_each do |tc|
              tc.status = 'pending'
              tt.save(validate: false)
            end
          end
        end
      end
       
      desc 'Reset the expired tag on all tickets, or pass in an ID to reset a single ticket. Ex: `rake clearinghouse:trip_tickets:development:unexpire[123]`'
      task :unexpire, [:id] => [:environment] do |t, args|
        args.with_defaults(:id => nil)
        tickets = TripTicket.where(expired: true)
        tickets = tickets.where(id: args.id) if args.id.to_i > 0
        # `each` is expensive, but we want to ensure an audit log is generated
        # and validations are ignored
        tickets.find_each do |tt|
          puts "Preparing to unexpire ticket ##{tt.id}"
          tt.expired = false
          tt.save(validate: false)
        end
      end

      desc 'Recalculate the appointment_time and expire_at attributes to occur in the future based on the offset of the original attribute from the created_at timestamp. (Caution: Will also update the created_at date!) Specify an ID to reset a single ticket. Ex: `rake clearinghouse:trip_tickets:development:unexpire[123]`'
      task :rebase_appointment_and_expiration_dates, [:id] => [:environment] do |t, args|
        args.with_defaults(:id => nil)
        tickets = TripTicket.scoped
        tickets = tickets.where(id: args.id) if args.id.to_i > 0
        TripTicket.transaction do
          tickets.find_each do |tt|
            puts "Preparing to rebase ticket ##{tt.id}"
            appointment_offset = tt.appointment_time.to_i - tt.created_at.to_i
            expiration_offset = tt.expire_at.to_i - tt.created_at.to_i if tt.expire_at.present?
            tt.appointment_time = Time.zone.now + appointment_offset.seconds
            tt.expire_at = Time.zone.now + expiration_offset.seconds if tt.expire_at.present?
            tt.expired = (tt.expire_at.present? && tt.expire_at >= Time.zone.now)
            tt.created_at = tt.appointment_time - appointment_offset.seconds # Preserve the offset
            tt.save(validate: false)
          end
        end
      end
    end
  end
end