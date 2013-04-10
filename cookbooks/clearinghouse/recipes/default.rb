include_recipe "apache2"
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

# --- Install Rails
gem_package "rails" do
  action :install
end

# --- Setup Apache2
# The passenger-apache cookbook has compiled the library all you need to do is 
# include the lines in your httpd.conf file.
# 
# Your rails app should be put into /srv/<your app> and be linked into /var/www
file "/etc/apache2/mods-enabled/phusion.load" do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "
LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-3.0.14/ext/apache2/mod_passenger.so
PassengerRoot /var/lib/gems/1.9.1/gems/passenger-3.0.14
PassengerRuby /usr/bin/ruby1.9.1
"
end

file "/etc/apache2/sites-enabled/000-default" do
  action :delete
end

file "/etc/apache2/sites-enabled/rails_project" do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "

# Set the size as 2 for 256MB VPS - How many Rack processes to start
# If you plan on running delayed_job then set this to 1 or up the memory to 512MB.
PassengerMaxPoolSize #{node[:passenger][:max_pool_size]}
#
# Single project
#
<VirtualHost *:80>
   ServerName ch.rideconnection.org
   # !!! Be sure to point DocumentRoot to 'public'!
   DocumentRoot #{node[:public_directory]}
   <Directory #{node[:public_directory]}>
      # This relaxes Apache security settings.
      AllowOverride all
      # MultiViews must be turned off.
      Options -MultiViews
   </Directory>
</VirtualHost>
#
# Multiple projects 
#
# Link your app from /srv/<app>/current/public to /var/www/<app>
# EG: ln -s /srv/pub.co/current/public /var/www/pub.co
#
# <VirtualHost *:80>
#         ServerName localhost
#         DocumentRoot /var/www
#         RailsBaseURI /<app1>
#         RailsBaseURI /<app2>
#         RailsBaseURI /<app3>
# </VirtualHost>

"
  not_if do
    File.exists?("/etc/apache2/sites-enabled/rails_project")
  end
end

# Setup permissions on deployment area.
execute "Add #{node[:linuxuser]} to group www-data" do
  command "usermod -a -G www-data #{node[:linuxuser]}"
end

execute "Change group on /srv" do 
  command "chown -R root:www-data /srv"
end

execute "Change permissions on /srv" do
  command "chmod -R 775 /srv"
end

execute "Create ssh directory" do
  command "mkdir -p /home/#{node[:linuxuser]}/.ssh"
end

file "/home/#{node[:linuxuser]}/.ssh/authorized_keys" do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAy8wqEnpZ8QxXLlpKLdI1Yjo7pegWlIodcVGp8bM92j1pqZrqq9dvyOjAe2m2fTATh8iOfowKXptfEKt3hEfxZrv55f4YTEb2ky6UOrW6L1NrJDSTrtgYQYX0QQ9ZEB02Im26ssBgOGrBSMDOuAp6wemRigyvFV2e2bnT1uzY7bgbf/OLaQTPPD64y3KSS8xd+CwrtmHUl/pIqqyZB1L7EvoDjP3JGGxtQhhLdnu3QeV3BtMQNhhHeLI7j7fZDnODFEjKlnAvMQenBHWY/7IJ+v9o/vENbLv4aAWOXlemN6nSw85HBjaknjp1iahYXdYQUfs6GkFS14NDAfdaCaNQqQ== mleone@tokyo.localdomain
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAudJPsL+XVdzFozj9dOt93feOR1IWT5uvaIDEAvub5kcu/z1v5kimXgFC7/KEK/HoDPLsjrQ4fHRkocWEW7uyF4Q+etE3wQT83E6EpPUEpRe4x7JRs2WmT5SVVy1t2lR+dWBFJLWmZh3ZSAnXgJbXFrwTqFB08BucBTGh2d1Mjo/Xi7lcsy9EIQnlRedLMTbB1o8XuML0AtAGkrZX5Z1uJ96j96GOdaVJYqskgbCZVejQUhNvZNSwYoB6GSBVy9PvwE5+RxGb89E/8hzLFastZKrkSn5ZTPirMOHEvdGnxPlCUyxoboohcqKy1A4Mt0Zb2lVm2E6BkmtfsCcFBMBYUw== chrisbloom7@gmail.com
" 
end 


# Setup gem sources
# execute "Add gem sources" do
#   command "gem sources -a http://gems.github.com"
#   not_if "gem sources -l | grep http://gems.github.com"
# end


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

# Install nokogiri requirements
package 'libxslt1-dev'
package 'libxml2-dev'

# Install ruby-debug
# gem_package "ruby-debug19" do
#   action :install
# end

# Install readline
# execute "Install readline" do
#   command "cd $rvm_path/src/$(rvm tools strings)/ext/readline;sudo ruby extconf.rb; sudo make; sudo make install"
# end

# RefineryCMS requirements
package "imagemagick"

# Check if passenger_apache2 is working
# Otherwise run this:
#
# execute "passenger_module" do
#   command 'echo -en "\n\n\n\n" | passenger-install-apache2-module'
#   creates node[:passenger][:module_path]
# end
