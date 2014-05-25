require 'test_helper'

class BulkOperationAbilityTest < ActiveSupport::TestCase
  setup do
    @roles = {
      :site_admin     => FactoryGirl.create(:role, :name => "site_admin"),
      :provider_admin => FactoryGirl.create(:role, :name => "provider_admin"),
      :scheduler      => FactoryGirl.create(:role, :name => "scheduler"),
      :dispatcher     => FactoryGirl.create(:role, :name => "dispatcher"),
      :read_only      => FactoryGirl.create(:role, :name => "read_only"),
      :api            => FactoryGirl.create(:role, :name => "api")
    }
  end

  # Per the Clearinghouse User Matrix only Site admins, Provider admins and schedulers should be able to perform bulk ticket actions.
  # bulk operations may only be accessed by the user that created them
  # bulk operations should only be created and read, not updated or destroyed
  # can [:create, :read], BulkOperation, :user_id => user.id
  # can :download, BulkOperation, :user_id => user.id, :is_upload => false

  def setup_for_role(role)
    @current_user = FactoryGirl.create(:user)
    @current_user.role = @roles[role]
    @current_ability = Ability.new(@current_user)
    @bulk_operation1 = FactoryGirl.create(:bulk_operation, user: @current_user)
    @bulk_operation2 = FactoryGirl.create(:bulk_operation, user: @current_user, is_upload: true)
    @bulk_operation3 = FactoryGirl.create(:bulk_operation)
  end

  [:site_admin, :provider_admin, :scheduler].each do |role|
    describe "#{role} role" do
      setup do
        setup_for_role(role)
      end

      it "can use accessible_by to load a list of bulk operations belonging to their user" do
        accessible = BulkOperation.accessible_by(@current_ability)
        accessible.must_include @bulk_operation1
        accessible.must_include @bulk_operation2
        accessible.wont_include @bulk_operation3
      end

      it "can create bulk operations" do
        assert @current_ability.can?(:create, BulkOperation)
      end

      it "can read bulk operations belonging to their own user" do
        assert @current_ability.can?(:read, @bulk_operation1)
        assert @current_ability.can?(:read, @bulk_operation2)
        assert @current_ability.cannot?(:read, @bulk_operation3)
      end

      it "cannot update bulk operations" do
        assert @current_ability.cannot?(:update, @bulk_operation1)
        assert @current_ability.cannot?(:update, @bulk_operation2)
        assert @current_ability.cannot?(:update, @bulk_operation3)
      end

      it "cannot destroy bulk operations" do
        assert @current_ability.cannot?(:destroy, @bulk_operation1)
        assert @current_ability.cannot?(:destroy, @bulk_operation2)
        assert @current_ability.cannot?(:destroy, @bulk_operation3)
      end

      it "can download the results of bulk operations that are not marked as uploads" do
        assert @current_ability.can?(:download, @bulk_operation1)
        assert @current_ability.cannot?(:download, @bulk_operation2)
        assert @current_ability.cannot?(:download, @bulk_operation3)
      end
    end
  end

  [:dispatcher, :read_only, :api].each do |role|
    describe "#{role} role" do
      setup do
        setup_for_role(role)
      end

      it "cannot use accessible_by to load a list of bulk operations" do
        accessible = BulkOperation.accessible_by(@current_ability)
        accessible.wont_include @bulk_operation1
        accessible.wont_include @bulk_operation2
        accessible.wont_include @bulk_operation3
      end

      it "cannot create bulk operations" do
        assert @current_ability.cannot?(:create, BulkOperation)
      end

      it "cannot read bulk operations" do
        assert @current_ability.cannot?(:read, @bulk_operation1)
        assert @current_ability.cannot?(:read, @bulk_operation2)
        assert @current_ability.cannot?(:read, @bulk_operation3)
      end

      it "cannot update bulk operations" do
        assert @current_ability.cannot?(:update, @bulk_operation1)
        assert @current_ability.cannot?(:update, @bulk_operation2)
        assert @current_ability.cannot?(:update, @bulk_operation3)
      end

      it "cannot destroy bulk operations" do
        assert @current_ability.cannot?(:destroy, @bulk_operation1)
        assert @current_ability.cannot?(:destroy, @bulk_operation2)
        assert @current_ability.cannot?(:destroy, @bulk_operation3)
      end

      it "cannot download the results of bulk operations" do
        assert @current_ability.cannot?(:download, @bulk_operation1)
        assert @current_ability.cannot?(:download, @bulk_operation2)
        assert @current_ability.cannot?(:download, @bulk_operation3)
      end
    end
  end
end
