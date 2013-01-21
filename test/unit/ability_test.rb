require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  it "Trip tickets can only be seen by users from organizations with a current, established relationship with the ticket owner" do
    provider_1 = FactoryGirl.create(:provider)
    provider_2 = FactoryGirl.create(:provider)
    provider_3 = FactoryGirl.create(:provider)
    user = FactoryGirl.create(:user, :provider => provider_1)
    relationship = ProviderRelationship.create!(
      :requesting_provider => provider_1,
      :cooperating_provider => provider_2
    )
    ticket_1 = FactoryGirl.create(:trip_ticket, :originator => provider_2)
    ticket_2 = FactoryGirl.create(:trip_ticket, :originator => provider_3)
    
    ability = Ability.new(user)
    assert ability.can?(:read, ticket_1)
    assert ability.cannot?(:read, ticket_2)
  end
end
