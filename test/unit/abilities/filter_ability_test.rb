require 'test_helper'

class FilterAbilityTest < ActiveSupport::TestCase
  setup do
    @current_user = FactoryGirl.create(:user)
    @other_user = FactoryGirl.create(:user)
    @filter1 = FactoryGirl.create(:filter, :user => @current_user, :name => "filter 1")
    @filter2 = FactoryGirl.create(:filter, :user => @current_user, :name => "filter 2")
    @filter3 = FactoryGirl.create(:filter, :user => @other_user, :name => "filter 3")
    @current_ability = Ability.new(@current_user)
  end

  describe "any user" do
    it "can use accessible_by to find filters they created" do
      accessible = Filter.accessible_by(@current_ability)
      accessible.must_include @filter1
      accessible.must_include @filter2
      accessible.wont_include @filter3
    end

    it "can create a filter" do
      assert @current_ability.can?(:create, @current_user.filters.build)
    end

    it "can read filters they created" do
      assert @current_ability.can?(:read, @filter1)
      assert @current_ability.can?(:read, @filter2)
      assert @current_ability.cannot?(:read, @filter3)
    end

    it "can update filters they created" do
      assert @current_ability.can?(:update, @filter1)
      assert @current_ability.can?(:update, @filter2)
      assert @current_ability.cannot?(:update, @filter3)
    end

    it "can destroy filters they created" do
      assert @current_ability.can?(:destroy, @filter1)
      assert @current_ability.can?(:destroy, @filter2)
      assert @current_ability.cannot?(:destroy, @filter3)
    end
  end
end
