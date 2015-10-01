seed_location = Location.find_or_create_by(common_name:  'Seed Location') do |l|
  l.address_1    = '123 Main St',
  l.city         = 'Portland',
  l.state        = 'OR',
  l.zip          = '12345',
  l.phone_number = '123-456-7890',
  l.jurisdiction = 'Multnomah'
end

seed_provider = Provider.find_or_create_by(name: 'Seed Provider') do |p|
  p.address               = seed_location
  p.primary_contact_email = 'seed@example.com'
end

seed_password = 'Password 1'
site_admin_role = Role.find_by name: 'site_admin'

seed_user = User.find_or_create_by(name: 'Seed User') do |u|
  u.provider              = seed_provider
  u.email                 = 'seed@example.com'
  u.password              = seed_password
  u.password_confirmation = seed_password
  u.role                  = site_admin_role
end
