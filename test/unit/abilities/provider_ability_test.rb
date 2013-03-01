require 'test_helper'

class ProviderAbilityTest < ActiveSupport::TestCase
  setup do
    @roles = {
      :site_admin     => FactoryGirl.create(:role, :name => "site_admin"),
      :provider_admin => FactoryGirl.create(:role, :name => "provider_admin"),
      :scheduler      => FactoryGirl.create(:role, :name => "scheduler"),
      :dispatcher     => FactoryGirl.create(:role, :name => "dispatcher"),
      :read_only      => FactoryGirl.create(:role, :name => "read_only")
    }

    @provider_1 = FactoryGirl.create(:provider)
    @provider_2 = FactoryGirl.create(:provider)
    @provider_3 = FactoryGirl.create(:provider)

    @provider_relationship_1 = ProviderRelationship.create!(:requesting_provider => @provider_1, :cooperating_provider => @provider_2)
    @provider_relationship_2 = ProviderRelationship.create!(:requesting_provider => @provider_2, :cooperating_provider => @provider_3)
    @provider_relationship_3 = ProviderRelationship.create!(:requesting_provider => @provider_3, :cooperating_provider => @provider_1)
    @provider_relationship_1.approve!
    @provider_relationship_2.approve!

    # All users can read their own provider or providers they have an approved relationship with
    # Provider admins can update and work with the keys of their own provider
    # No user can destroy providers
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of providers regardless of the provider" do
      accessible = Provider.accessible_by(@site_admin)
      accessible.must_include @provider_1
      accessible.must_include @provider_2
      accessible.must_include @provider_3
    end

    it "can create providers" do
      assert @site_admin.can?(:create, Provider.new)
    end

    it "can read open capacities regardless of the provider" do
      assert @site_admin.can?(:read, @provider_1)
      assert @site_admin.can?(:read, @provider_2)
      assert @site_admin.can?(:read, @provider_3)
    end

    it "can update open capacities regardless of the provider" do
      assert @site_admin.can?(:update, @provider_1)
      assert @site_admin.can?(:update, @provider_2)
      assert @site_admin.can?(:update, @provider_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @site_admin.cannot?(:destroy, @provider_1)
      assert @site_admin.cannot?(:destroy, @provider_2)
      assert @site_admin.cannot?(:destroy, @provider_3)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load their own provider or providers they have an approved relationship with" do
      accessible = Provider.accessible_by(@provider_admin)
      accessible.must_include @provider_1
      accessible.must_include @provider_2
      accessible.wont_include @provider_3
    end
    
    it "cannot create providers" do
      assert @provider_admin.cannot?(:create, Provider.new)
    end
    
    it "can read their own provider or providers they have an approved relationship with" do
      assert @provider_admin.can?(:read, @provider_1)
      assert @provider_admin.can?(:read, @provider_2)
      assert @provider_admin.cannot?(:read, @provider_3)
    end
    
    it "can update their own provider" do
      assert @provider_admin.can?(:update, @provider_1)
      assert @provider_admin.cannot?(:update, @provider_2)
      assert @provider_admin.cannot?(:update, @provider_3)
    end
    
    it "cannot destroy their own provider or any other provider" do
      assert @provider_admin.cannot?(:destroy, @provider_1)
      assert @provider_admin.cannot?(:destroy, @provider_2)
      assert @provider_admin.cannot?(:destroy, @provider_3)
    end
    
    it "can view the keys of their own provider" do
      assert @provider_admin.can?(:keys, @provider_1)
      assert @provider_admin.cannot?(:keys, @provider_2)
      assert @provider_admin.cannot?(:keys, @provider_3)
    end
    
    it "can reset the keys of their own provider" do
      assert @provider_admin.can?(:reset_keys, @provider_1)
      assert @provider_admin.cannot?(:reset_keys, @provider_2)
      assert @provider_admin.cannot?(:reset_keys, @provider_3)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to load their own provider or providers they have an approved relationship with" do
      accessible = Provider.accessible_by(@scheduler)
      accessible.must_include @provider_1
      accessible.must_include @provider_2
      accessible.wont_include @provider_3
    end
    
    it "cannot create providers" do
      assert @scheduler.cannot?(:create, Provider.new)
    end
    
    it "can read their own provider or providers they have an approved relationship with" do
      assert @scheduler.can?(:read, @provider_1)
      assert @scheduler.can?(:read, @provider_2)
      assert @scheduler.cannot?(:read, @provider_3)
    end
    
    it "cannot update any own provider" do
      assert @scheduler.cannot?(:update, @provider_1)
      assert @scheduler.cannot?(:update, @provider_2)
      assert @scheduler.cannot?(:update, @provider_3)
    end
    
    it "cannot destroy their own provider or any other provider" do
      assert @scheduler.cannot?(:destroy, @provider_1)
      assert @scheduler.cannot?(:destroy, @provider_2)
      assert @scheduler.cannot?(:destroy, @provider_3)
    end
    
    it "cannot view the keys of their own provider" do
      assert @scheduler.cannot?(:keys, @provider_1)
      assert @scheduler.cannot?(:keys, @provider_2)
      assert @scheduler.cannot?(:keys, @provider_3)
    end
    
    it "cannot reset the keys of their own provider" do
      assert @scheduler.cannot?(:reset_keys, @provider_1)
      assert @scheduler.cannot?(:reset_keys, @provider_2)
      assert @scheduler.cannot?(:reset_keys, @provider_3)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to load their own provider or providers they have an approved relationship with" do
      accessible = Provider.accessible_by(@dispatcher)
      accessible.must_include @provider_1
      accessible.must_include @provider_2
      accessible.wont_include @provider_3
    end
    
    it "cannot create providers" do
      assert @dispatcher.cannot?(:create, Provider.new)
    end
    
    it "can read their own provider or providers they have an approved relationship with" do
      assert @dispatcher.can?(:read, @provider_1)
      assert @dispatcher.can?(:read, @provider_2)
      assert @dispatcher.cannot?(:read, @provider_3)
    end
    
    it "cannot update any own provider" do
      assert @dispatcher.cannot?(:update, @provider_1)
      assert @dispatcher.cannot?(:update, @provider_2)
      assert @dispatcher.cannot?(:update, @provider_3)
    end
    
    it "cannot destroy their own provider or any other provider" do
      assert @dispatcher.cannot?(:destroy, @provider_1)
      assert @dispatcher.cannot?(:destroy, @provider_2)
      assert @dispatcher.cannot?(:destroy, @provider_3)
    end
    
    it "cannot view the keys of their own provider" do
      assert @dispatcher.cannot?(:keys, @provider_1)
      assert @dispatcher.cannot?(:keys, @provider_2)
      assert @dispatcher.cannot?(:keys, @provider_3)
    end
    
    it "cannot reset the keys of their own provider" do
      assert @dispatcher.cannot?(:reset_keys, @provider_1)
      assert @dispatcher.cannot?(:reset_keys, @provider_2)
      assert @dispatcher.cannot?(:reset_keys, @provider_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to load their own provider or providers they have an approved relationship with" do
      accessible = Provider.accessible_by(@read_only)
      accessible.must_include @provider_1
      accessible.must_include @provider_2
      accessible.wont_include @provider_3
    end
    
    it "cannot create providers" do
      assert @read_only.cannot?(:create, Provider.new)
    end
    
    it "can read their own provider or providers they have an approved relationship with" do
      assert @read_only.can?(:read, @provider_1)
      assert @read_only.can?(:read, @provider_2)
      assert @read_only.cannot?(:read, @provider_3)
    end
    
    it "cannot update any own provider" do
      assert @read_only.cannot?(:update, @provider_1)
      assert @read_only.cannot?(:update, @provider_2)
      assert @read_only.cannot?(:update, @provider_3)
    end
    
    it "cannot destroy their own provider or any other provider" do
      assert @read_only.cannot?(:destroy, @provider_1)
      assert @read_only.cannot?(:destroy, @provider_2)
      assert @read_only.cannot?(:destroy, @provider_3)
    end
    
    it "cannot view the keys of their own provider" do
      assert @read_only.cannot?(:keys, @provider_1)
      assert @read_only.cannot?(:keys, @provider_2)
      assert @read_only.cannot?(:keys, @provider_3)
    end
    
    it "cannot reset the keys of their own provider" do
      assert @read_only.cannot?(:reset_keys, @provider_1)
      assert @read_only.cannot?(:reset_keys, @provider_2)
      assert @read_only.cannot?(:reset_keys, @provider_3)
    end
  end
end
