require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  describe "trip tickets" do
    setup do
      @provider_1 = FactoryGirl.create(:provider)
      @provider_2 = FactoryGirl.create(:provider)
      @provider_3 = FactoryGirl.create(:provider)
      @user = FactoryGirl.create(:user, :provider => @provider_1)
      @relationship = ProviderRelationship.create!(
        :requesting_provider  => @provider_1,
        :cooperating_provider => @provider_2
      )
      @ticket_1 = FactoryGirl.create(:trip_ticket, :originator => @provider_2)
      @ticket_2 = FactoryGirl.create(:trip_ticket, :originator => @provider_3)
    end
    
    teardown do
      @ticket_2.destroy
      @ticket_1.destroy
      @relationship.destroy
      @user.destroy
      @provider_3.destroy
      @provider_2.destroy
      @provider_1.destroy
    end
    
    it "can only be seen by non-administrative users from organizations with a current, established relationship with the originating provider" do
      ability = Ability.new(@user)
      assert ability.can?(:read, @ticket_1)
      assert ability.cannot?(:read, @ticket_2)
    end
    
    it "can be seen by site administrators regardless of provider relationships" do
      @user.roles << Role.find_or_create_by_name(:site_admin)
      ability = Ability.new(@user)
      assert ability.can?(:read, @ticket_1)
      assert ability.can?(:read, @ticket_2)
    end
  end
end
