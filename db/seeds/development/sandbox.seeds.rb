if User.find_by_email('site_admin@clearinghouse.org').present?
  puts "-- Skipping sandbox data - already loaded"
else
  ActiveRecord::Base.transaction do
    puts "-- Loading sandbox data"
  
    provider_1 = FactoryGirl.create(:provider, :name => "Google")
    provider_2 = FactoryGirl.create(:provider, :name => "Yahoo")
    provider_3 = FactoryGirl.create(:provider, :name => "Microsoft")

    provider_relationship_1 = ProviderRelationship.create!(:requesting_provider => provider_1, :cooperating_provider => provider_2)
    provider_relationship_2 = ProviderRelationship.create!(:requesting_provider => provider_2, :cooperating_provider => provider_3)
    provider_relationship_3 = ProviderRelationship.create!(:requesting_provider => provider_3, :cooperating_provider => provider_1)
    provider_relationship_1.approve!
    provider_relationship_2.approve!

    # Open trip ticket from provider_1
    trip_ticket_1  = FactoryGirl.create(:trip_ticket, :originator => provider_1)
    FactoryGirl.create(:trip_claim, :trip_ticket => trip_ticket_1, :claimant => provider_2, :status => TripClaim::STATUS[:pending])

    # Claimed trip ticket from provider_1
    trip_ticket_2  = FactoryGirl.create(:trip_ticket, :originator => provider_1)
    FactoryGirl.create(:trip_claim, :trip_ticket => trip_ticket_2, :claimant => provider_2, :status => TripClaim::STATUS[:approved])

    # Open trip ticket from provider_2, no claims
    trip_ticket_3  = FactoryGirl.create(:trip_ticket, :originator => provider_2)

    # Claimed trip ticket from provider_2
    trip_ticket_4  = FactoryGirl.create(:trip_ticket, :originator => provider_2)
    FactoryGirl.create(:trip_claim, :trip_ticket => trip_ticket_4, :claimant => provider_1, :status => TripClaim::STATUS[:declined])
    FactoryGirl.create(:trip_claim, :trip_ticket => trip_ticket_4, :claimant => provider_3, :status => TripClaim::STATUS[:approved])

    # Open trip ticket from provider_3, no claims
    trip_ticket_5  = FactoryGirl.create(:trip_ticket, :originator => provider_3)

    # Claimed trip ticket from provider_3
    trip_ticket_6  = FactoryGirl.create(:trip_ticket, :originator => provider_3)
    FactoryGirl.create(:trip_claim, :trip_ticket => trip_ticket_6, :claimant => provider_2, :status => TripClaim::STATUS[:approved])
  
    user_password = "password 1"

    site_admin = FactoryGirl.create(:user, :provider => provider_1, :email => "site_admin@clearinghouse.org", :name => "Site Admin", :password => user_password, :password_confirmation => user_password)
    site_admin.role = Role.find_by_name("site_admin")
    puts "User site_admin@clearinghouse.org created with password '#{user_password}'"
    
    [provider_1, provider_2, provider_3].each_with_index do |provider,index|
      FactoryGirl.create(:service, :provider => provider, :name => "#{provider.name} service 1")
      FactoryGirl.create(:service, :provider => provider, :name => "#{provider.name} service 2")
    
      Role.provider_roles.each do |role|
        email = "#{role.name.underscore}_#{index + 1}@clearinghouse.org"
        name  = "Test #{role.name.titlecase} #{index + 1}"

        user = FactoryGirl.create(:user, :provider => provider, :email => email, :name => name, :password => user_password, :password_confirmation => user_password)
        user.role = role
        puts "User #{email} created with password '#{user_password}'"
      end
    end
  
    puts "-- Done loading sandbox data"
  end
end
