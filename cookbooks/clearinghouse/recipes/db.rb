include_recipe "postgresql::server"

# --- Install packages we need ---
package 'fail2ban' # Security for login attempts
package 'mutt'     # Email client
package 'sysstat'  # Monitor io
package 'nethogs'  # Monitor network
package 'htop'     # Better than top
package 'vim'
package 'screen'
package 'apt-file'
package 'command-not-found'
#package 'nodejs'

# Setup postgres user
# sudo -u postgres createuser -sw map7
# Set dbuser in your solo.json file.
execute "create-database-user" do
  code = <<-EOH
sudo -u postgres psql -c "select * from pg_user where usename='#{node[:dbuser]}'" | grep -c #{node[:dbuser]}
EOH
#  command "sudo -u postgres createuser -sw #{node[:dbuser]}"
  command "sudo -u postgres psql -c \"create user #{node[:dbuser]} with password '#{node[:dbpass]}' createdb createuser\";"
  not_if code 
end

package "postgresql-contrib" 
package "postgresql-contrib-8.4"
package "postgresql-8.4-postgis"

# Turns out the firewall is disabled on these servers anyway, so no additional
# rules are required. If we need to add them later, we should use the "firewall"
# cookbook from chef-ops instead.
# execute "setup-firewall-rules" do
#   command "iptables -A INPUT -p tcp -s #{node[:ip_addresses][:db_server]} --sport 1024:65535 -d #{node[:ip_addresses][:web_server]} --dport 5432 -m state --state NEW,ESTABLISHED -j ACCEPT"
#   command "iptables -A OUTPUT -p tcp -s #{node[:ip_addresses][:web_server]} --sport 5432 -d #{node[:ip_addresses][:db_server]} --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT"
# end
