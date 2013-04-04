package 'ntp'
package 'sysstat'
package 'apache2'

# --- Set host name ---
# Note how this is plain Ruby code, so we can define variables to
# DRY up our code:
hostname = 'ch.rideconnection.org'

file '/etc/hostname' do
  content "#{hostname}\n"
end

service 'hostname' do
  action :restart
end

file '/etc/hosts' do
  content "127.0.0.1 localhost #{hostname}\n"
end

# --- Deploy a configuration file ---
# For longer files, when using 'content "..."' becomes too
# cumbersome, we can resort to deploying separate files:
cookbook_file '/etc/apache2/apache2.conf'
# This will copy cookbooks/op/files/default/apache2.conf (which
# you'll have to create yourself) into place. Whenever you edit
# that file, simply run "./deploy.sh" to copy it to the server.

service 'apache2' do
  action :restart
end
