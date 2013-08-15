# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

set :output, "#{path}/log/cron.log"

every '0 * * * *', :roles => [:app] do
  rake 'clearinghouse:trip_tickets:expire'
end
