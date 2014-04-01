include_recipe "apache2"
include_recipe "postgresql::client"

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
LoadModule passenger_module /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.14/ext/apache2/mod_passenger.so
PassengerRoot /usr/local/lib/ruby/gems/1.9.1/gems/passenger-3.0.14
PassengerRuby /usr/local/bin/ruby
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

<VirtualHost *:443>
  ServerName ch.rideconnection.org
  DocumentRoot #{node[:public_directory]}
  <Directory #{node[:public_directory]}>
    AllowOverride all
    Options -MultiViews
  </Directory>

  SSLEngine on
  SSLOptions +StrictRequire
  SSLCertificateFile #{node[:ssl_cert]} 
  SSLCertificateKeyFile #{node[:ssl_cert_key]} 
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
end

execute "Install apache SSL dependencies" do 
  command "a2enmod ssl"
  command "a2enmod rewrite"
end

# Setup permissions on deployment area.
execute "Add #{node[:linuxuser]} to group www-data" do
  command "usermod -a -G www-data #{node[:linuxuser]}"
end

execute "Change group on /srv" do 
  command "chown -R #{node[:linuxuser]} /srv"
end

execute "Change permissions on /srv" do
  command "chmod -R 775 /srv"
end

execute "Create ssh directory" do
  command "mkdir -p /home/#{node[:linuxuser]}/.ssh"
end

execute "Ensure etc/apache2/certs exists" do
  command "mkdir -p etc/apache2/certs"
end

file node[:ssl_cert] do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "-----BEGIN CERTIFICATE-----
MIIFQDCCBCigAwIBAgIHK3gO9vWfMjANBgkqhkiG9w0BAQsFADCBtDELMAkGA1UE
BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY
BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMu
Z29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3Vy
ZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0xMzA3MjUxNzQyMDNaFw0x
NjA3MjUxNzQyMDNaMEMxITAfBgNVBAsTGERvbWFpbiBDb250cm9sIFZhbGlkYXRl
ZDEeMBwGA1UEAxMVY2gucmlkZWNvbm5lY3Rpb24ub3JnMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAs0PRmKZM/P+dAXiSeUR0tn+S3jHNSzH+OMs0Fo25
5T8LyjEdDpaAoQZm2mZT6PUJtxuv1fyywNXv1q4U8NkQomYHUAlmqf3EDIeviOPp
rC6aF5C/0E9cHLNe7FzVTvuB2nH7gECNivHtK0rSkVrjxk/j8DVePtR0YR2c2qMd
ZI564tS684HtqSBjqC6zcaLkzbuQd2e+iVA1xgRU61nHd4LvzX9gZoGtAbTeQneR
3Yc8rr2uuOo0pdTgH/LCX83IjqBwOuRw+v48dZAwZfGtY//YzZTLAakd1DgbEtRl
O2jiCJA4Ore4CBfy+HWOeHQrQh+oPm4XKPLF2+8TY8hGlwIDAQABo4IBxTCCAcEw
DwYDVR0TAQH/BAUwAwEBADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIw
DgYDVR0PAQH/BAQDAgWgMDUGA1UdHwQuMCwwKqAooCaGJGh0dHA6Ly9jcmwuZ29k
YWRkeS5jb20vZ2RpZzJzMS0xLmNybDBTBgNVHSAETDBKMEgGC2CGSAGG/W0BBxcB
MDkwNwYIKwYBBQUHAgEWK2h0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20v
cmVwb3NpdG9yeS8wdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8v
b2NzcC5nb2RhZGR5LmNvbS8wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jZXJ0aWZpY2F0
ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS9nZGlnMi5jcnQwHwYDVR0jBBgwFoAU
QMK9J47MNIMwojPX+2yz8LQsgM4wOwYDVR0RBDQwMoIVY2gucmlkZWNvbm5lY3Rp
b24ub3Jnghl3d3cuY2gucmlkZWNvbm5lY3Rpb24ub3JnMB0GA1UdDgQWBBRKZNiV
up+DvsAL5DJC3zH/JV5jgDANBgkqhkiG9w0BAQsFAAOCAQEAWI8rqDqHJnDOSjfm
3viXXqtNvUap+9srKHA0pbvHq/FjtzntKyWuCO05aNczthT0E2X8h8bgcJ2kG6/h
tVgq2CJap0keMeQ0jpAWaNKd7CXh8AVmhKyo2kNbSdQkJKpa1VzR7PEOXZFEHuh9
PKPhyFLpl60rv245s2hC/ckkManwlgbaPd+WJbKQTen5RRtMCkKhPGP6qrMyuvV6
hMQ4h37vf6JpAdvHkvGZ2xdPOZOfov1eWoDkyCNbVBaG7jhhI5Oe5RbTAffwAAGd
faefZIQLT48fscjv2iSnZlzWs3FLMcWLNUz8pkZgI1KkDeMaI4lDu1ZmwlVAZir8
BMqtNg==
-----END CERTIFICATE-----"
end

file node[:ssl_cert_key] do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAs0PRmKZM/P+dAXiSeUR0tn+S3jHNSzH+OMs0Fo255T8LyjEd
DpaAoQZm2mZT6PUJtxuv1fyywNXv1q4U8NkQomYHUAlmqf3EDIeviOPprC6aF5C/
0E9cHLNe7FzVTvuB2nH7gECNivHtK0rSkVrjxk/j8DVePtR0YR2c2qMdZI564tS6
84HtqSBjqC6zcaLkzbuQd2e+iVA1xgRU61nHd4LvzX9gZoGtAbTeQneR3Yc8rr2u
uOo0pdTgH/LCX83IjqBwOuRw+v48dZAwZfGtY//YzZTLAakd1DgbEtRlO2jiCJA4
Ore4CBfy+HWOeHQrQh+oPm4XKPLF2+8TY8hGlwIDAQABAoIBAAn04ldQJUaIC/hg
8gG6Q6E/RLECoxxiEnSlFKeMB58r+UOppquAwHQxHtVSiaaOtZNt/j4sYuFDAKcz
1AXsiHf8ortXSlR2u8TWZHF99ySREg3tBDpVrhAKBmOqZE6WuYegfQ+KhlIJTdrx
tPBN1AjXtxlIXYuv0SbzthqOpLtI9s2n/Ifp2+fukco3tc+VQZhatLrxPY0JaC3a
FE7P5MsO6C87pmZX86OdVbZxTutAe4gEhvXVT5T/IaZRWTf2j6MT0yZ+pmpzgllF
ydRhDQrMuI/TVRbS5Ra9oUz1x86m/lf0+CGlsLTzj/2E+1uCy9dKtLxO0jLkyliM
PeMrTkECgYEA2XFx2D2Ek/2sCB+LGpU7FGy/qwWJ2KxQcGSHnEG5NU5D7hEV0L2E
9IJZDZz9TPFeTf1r1Xj7ofvBhgqaSJ8UObcGroBgfbjnjNo+Cvl2kZdsfuJtchrA
ND+XesapauKb372kRuI/o/jV8haI6eBJhJe4xw1zbVokLPATRJOzGb0CgYEA0w1S
alBD+VUyaGtGwou7kGf+6hx9Fu8TqL0Jypq0AnshhYYhJb57vL9uSekQHcehbCAn
uQNt6SXyQGGnRwXx2Y7G5HLvEZAo6ljrhyuTM7jCYFm4KX0ilsIChavhf/FcIU/A
nQwag9axnuhTiz22Ow4XQ7jjIzeHVieY9s0vhOMCgYEAggwTZp0EWe5xoTocW/28
o+6Wg5aAZxJH2bCGWrIELxlsD0ownfN7PTFoSXgHFqmVGVfj0nzVIoALsjtNIvnh
gtMwL9Wf4BFiix9L1Ax3GYRS42BQzNmq8pTF6CxAzyhQyXQGeE6AeXUtn+hSYm4+
Cgsj/AjTbCdpU2cSXwVnLJECgYB0J5/VPSm7/uTITUpbZhYrquDELju2NIxoUOoj
pLMvrl7Lov95S3XEcsMbUHb7PNSdsrDKBZYnPCgwwM4Uq7PoncjfEFZ9Hw81swyl
jxjr3WK1LovJ4cH4oPxMX0Wzab3f44nJpVCugKmvIIRiXOt/Ywjwz7/KsRP+Gbr5
EgJ2KwKBgA+/cc/gLyspHqkywYWCvFAxSG6emMdLt2hXsh9QIJa5x6gR7EDaKwPT
3KiIX3zCe+HblN3LLx443mFigZPUIIhgQZP9771OYWkdiLbmsoXPWTUaTypyvGif
BJC95IdhD+/CnyqeoAFmPA5S7TLdS/07GslnaoyKzhXyo5qET/yb
-----END RSA PRIVATE KEY-----"
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

file "/home/#{node[:linuxuser]}/.ssh/id_rsa" do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "-----BEGIN RSA PRIVATE KEY-----
MIIEoQIBAAKCAQEA0NSSsUtVRWVJz95ZW5+iDSXsd5Io/Lf/dU7mEFqfkhtAnsLy
dKjyo/1b731CQvvsHydMlaViRzJ0/B7z9K1LWgPCeZ4BM3/3JzOnCsP/+3cQ4JGP
shQfEoDMh9fx3x/fMTHmkrKAWJiXHOjihHHsrQJQm/aDHqC29D4fT6SRNWw4Pt/F
Za8/BKM0uXRpV3ZXCQThiwpRVQsUI8o4zVHK4W49C0M35+L5A+3TlsN5YHEH7sbK
mMu3MigJ4qhX94Qx8v6kHbS7d/gTqVvQz1hY4PnjQ2NgfRdWpVmB89P3NejBqgid
ylGw5/H82njDs3MhBdvy+C7fbXRZp1QJO2NLIwIBIwKCAQBrZgJMjSSKFtWA2MA9
v8+u/Y+N82WJSK9DpOtY3iYt4iE7tLc0rqisG+YjZP2BiN/VgezfPxyZpOu03Lf6
LTyx804SqQfumZUM2LxOrfFcwOQbuJMLIEp+i2Hfdl8iSufQKEqx2CS/2XJJYdOU
klx2O7Rtd3aiCYKpfwjJ35siyQMyrLiytZZmgQ1YJySjRP6t47hcll/D85aG6X+0
rFynPqvJ6kQa281OJAlxkFrAbTLbwyLaGA+h7HOp//7UOAqkw43H3qtMpwh71Q/V
fIcNF0SYvztNe4NG1zNpeSmqAzysBfaX+QqFAo5eqKUOOp90OkyN6lCSH8WmtZvA
IVxbAoGBAOpQQuJvSAQBxu6O1QeoZdHvYmXFjqjY2NDDbyJ4+FcUIg9FW/ZqvT1n
7UCZHC+avrwCzI6RQa658GqdFGDNbGbleYI+pewtvaTc0daQFcs2zSmFLVIP5F+v
rMQ0GtMLEsDQRo50bb1BamTvhBZWgJuTc1vajzjSDAXfpeJTt0A3AoGBAOQohe2a
6bMCqHNUjCiqfCQc2XjYkCcp2J6vXCw8Jr+kizUSn70QCI/11vJn8ieIbDAkN7Em
lCL2QTAlsGs4HJnplxxopPP8Svq/Tz8Ds/jX1NDOF4zkws0IX6Dkaf3SCJkZfZNn
RtD5O4MWc94zDsEs2slfArSbuMU8aXgOh551AoGAfzLieuvz5OsFl3Ib35XuIYHz
llVNcZpJ0GoXwkGrYnikxnYb+sw62DEaZOVnEoc0V2872F17bXrhmPYvokOhPywd
Y/YfjtcAjLJjSJdcSb6p41bst4T4UTN7C2y+Gst/NXhg0P1gJOj/Phufedcv321N
QH31+kYjyKyb4UNjeqECgYEAle6+aPDFdaKpNdh5XI1KQ53t/vS2gCLQLcOxmWlb
SryV/k4RMxkqMrd+n0ufIUsFRDUOp50CQtxWuT1WrNu7Bg6H33f3XoE4liXyP1o0
cFNRVgPGVUXfGQWAq47JTwZda+wt8yacQC7AtTqj6cnH3geIdbN2znT1w3DXmAmM
Ui8CgYAy7oFPL8UJZYfbO3vHZIexf68oRg8/rZXPzagiK+Gz3rISGzTvDP74sQM4
4pVZcz2FiOnaGrIfoy9u+lJ06cpmOiAjAD0koOKJq/L/ZFux/XiGZ6Hq8d4QBDzf
ebrumip6fQfnZMk4OB5BJ9MtvP3WBljPgw0SMkYFnuZpVk/QOA==
-----END RSA PRIVATE KEY-----" 
end 

file "/home/#{node[:linuxuser]}/.ssh/id_rsa.pub" do
  owner "root"
  group "root"
  mode "0644"
  action :create
  content "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0NSSsUtVRWVJz95ZW5+iDSXsd5Io/Lf/dU7mEFqfkhtAnsLydKjyo/1b731CQvvsHydMlaViRzJ0/B7z9K1LWgPCeZ4BM3/3JzOnCsP/+3cQ4JGPshQfEoDMh9fx3x/fMTHmkrKAWJiXHOjihHHsrQJQm/aDHqC29D4fT6SRNWw4Pt/FZa8/BKM0uXRpV3ZXCQThiwpRVQsUI8o4zVHK4W49C0M35+L5A+3TlsN5YHEH7sbKmMu3MigJ4qhX94Qx8v6kHbS7d/gTqVvQz1hY4PnjQ2NgfRdWpVmB89P3NejBqgidylGw5/H82njDs3MhBdvy+C7fbXRZp1QJO2NLIw== admin@rideconnection.org"
end

# Setup gem sources
# execute "Add gem sources" do
#   command "gem sources -a http://gems.github.com"
#   not_if "gem sources -l | grep http://gems.github.com"
# end

# Install nokogiri requirements
package 'libxslt1-dev'
package 'libxml2-dev'

package "postgresql-contrib" 
package "postgresql-contrib-8.4"

package "imagemagick"
