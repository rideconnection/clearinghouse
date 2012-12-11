class << self
  def find_or_create_user_by_role_name_and_index(role_name, index)
    email = "#{role_name.to_s.underscore}#{index.blank? ? "" : "_#{index}"}@clearinghouse.org"
    name  = "Test #{role_name.to_s.titlecase}#{index.blank? ? "" : " #{index}"}"
    pass  = "password 1"
    User.find_or_create_by_email!(email: email, password: pass, password_confirmation: pass, name: name)
  end
end

admin_roles = [:site_admin, :provider_admin]
ActiveRecord::Base.transaction do
  puts "-- Loading sandbox data"
  sa = find_or_create_user_by_role_name_and_index(:site_admin, nil)
  puts "---- Site Admin: \"#{sa.email}\""
  
  2.times do |i|
    index = i + 1
    p = Provider.find_or_initialize_by_name("Provider \##{index}")
    pc = find_or_create_user_by_role_name_and_index(:provider_admin, index)

    p.address = Location.create(address_1: "#{index} Clearing House Rd", city: "Portland", state: "OR", zip: "97210") unless p.address.present?
    p.primary_contact = pc unless p.primary_contact.present?
    p.save! if p.changed?
    puts "---- Provider \##{index}: \"#{p.name}\""
    
    pc.provider = p unless pc.provider.present?
    pc.save! if pc.changed?
    puts "------ Provider Admin: \"#{pc.email}\""
    
    Role.where('name NOT IN (?)', admin_roles).each do |role|
      u = find_or_create_user_by_role_name_and_index(role.name, i+1)
      u.provider = p unless u.provider.present?
      u.roles << role unless u.roles.include?(role)
      u.save! if u.changed?
      puts "------ #{role.name.titlecase}: \"#{u.email}\""
    end
  end
  puts "-- Done loading sandbox data"
end
