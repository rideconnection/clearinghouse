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
