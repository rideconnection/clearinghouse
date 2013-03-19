require 'test_helper'

class ProviderRelationshipAbilityTest < ActiveSupport::TestCase
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

    # Provider admins can read provider relationships that their own provider belongs to
    # Provider admins can update and destroy provider relationships that their own provider belongs to
    # Provider admins can activate (aka approve) provider relationships sent to their own provider
    # Provider admins can create provider relationships originating from their own provider
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
      accessible = ProviderRelationship.accessible_by(@site_admin)
      accessible.must_include @provider_relationship_1
      accessible.wont_include @provider_relationship_2
      accessible.must_include @provider_relationship_3
    end
    
    it "can create provider relationships originating from their own provider" do
      assert @site_admin.cannot?(:create, ProviderRelationship.new)
      assert @site_admin.can?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))    
      assert @site_admin.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
      assert @site_admin.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
    end
    
    it "can read provider relationships that their own provider belongs to" do
      assert @site_admin.can?(:read, @provider_relationship_1)
      assert @site_admin.cannot?(:read, @provider_relationship_2)
      assert @site_admin.can?(:read, @provider_relationship_3)    
    end
    
    it "can update provider relationships that their own provider belongs to" do
      assert @site_admin.can?(:update, @provider_relationship_1)
      assert @site_admin.cannot?(:update, @provider_relationship_2)
      assert @site_admin.can?(:update, @provider_relationship_3)    
    end
    
    it "can destroy provider relationships that their own provider belongs to" do
      assert @site_admin.can?(:destroy, @provider_relationship_1)    
      assert @site_admin.cannot?(:destroy, @provider_relationship_2)
      assert @site_admin.can?(:destroy, @provider_relationship_3)
    end
    
    it "can activate (aka approve) provider relationships sent to their own provider" do      
      assert @site_admin.cannot?(:activate, @provider_relationship_1)
      assert @site_admin.cannot?(:activate, @provider_relationship_2)
      assert @site_admin.can?(:activate, @provider_relationship_3)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
      accessible = ProviderRelationship.accessible_by(@provider_admin)
      accessible.must_include @provider_relationship_1
      accessible.wont_include @provider_relationship_2
      accessible.must_include @provider_relationship_3
    end
    
    it "can create provider relationships originating from their own provider" do
      assert @provider_admin.cannot?(:create, ProviderRelationship.new)
      assert @provider_admin.can?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))    
      assert @provider_admin.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
      assert @provider_admin.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
    end
    
    it "can read provider relationships that their own provider belongs to" do
      assert @provider_admin.can?(:read, @provider_relationship_1)
      assert @provider_admin.cannot?(:read, @provider_relationship_2)
      assert @provider_admin.can?(:read, @provider_relationship_3)    
    end
    
    it "can update provider relationships that their own provider belongs to" do
      assert @provider_admin.can?(:update, @provider_relationship_1)
      assert @provider_admin.cannot?(:update, @provider_relationship_2)
      assert @provider_admin.can?(:update, @provider_relationship_3)    
    end
    
    it "can destroy provider relationships that their own provider belongs to" do
      assert @provider_admin.can?(:destroy, @provider_relationship_1)    
      assert @provider_admin.cannot?(:destroy, @provider_relationship_2)
      assert @provider_admin.can?(:destroy, @provider_relationship_3)
    end
    
    it "can activate (aka approve) provider relationships sent to their own provider" do      
      assert @provider_admin.cannot?(:activate, @provider_relationship_1)
      assert @provider_admin.cannot?(:activate, @provider_relationship_2)
      assert @provider_admin.can?(:activate, @provider_relationship_3)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
      accessible = ProviderRelationship.accessible_by(@scheduler)
      accessible.must_include @provider_relationship_1
      accessible.wont_include @provider_relationship_2
      accessible.must_include @provider_relationship_3
    end
    
    it "cannot create provider relationships regardless of the provider" do    
      assert @scheduler.cannot?(:create, ProviderRelationship.new)
      assert @scheduler.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))
      assert @scheduler.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
      assert @scheduler.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
    end
    
    it "can read provider relationships that their own provider belongs to" do
      assert @scheduler.can?(:read, @provider_relationship_1)
      assert @scheduler.cannot?(:read, @provider_relationship_2)
      assert @scheduler.can?(:read, @provider_relationship_3)
    end
    
    it "cannot update provider relationships regardless of the provider" do
      assert @scheduler.cannot?(:update, @provider_relationship_1)    
      assert @scheduler.cannot?(:update, @provider_relationship_2)
      assert @scheduler.cannot?(:update, @provider_relationship_3)
    end
    
    it "cannot destroy provider relationships regardless of the provider" do
      assert @scheduler.cannot?(:destroy, @provider_relationship_1)
      assert @scheduler.cannot?(:destroy, @provider_relationship_2)
      assert @scheduler.cannot?(:destroy, @provider_relationship_3)
    end
    
    it "cannot activate (aka approve) provider relationships regardless of the provider" do
      assert @scheduler.cannot?(:activate, @provider_relationship_1)
      assert @scheduler.cannot?(:activate, @provider_relationship_2)
      assert @scheduler.cannot?(:activate, @provider_relationship_3)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
      accessible = ProviderRelationship.accessible_by(@dispatcher)
      accessible.must_include @provider_relationship_1
      accessible.wont_include @provider_relationship_2
      accessible.must_include @provider_relationship_3
    end
    
    it "cannot create provider relationships regardless of the provider" do    
      assert @dispatcher.cannot?(:create, ProviderRelationship.new)
      assert @dispatcher.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))
      assert @dispatcher.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
      assert @dispatcher.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
    end
    
    it "can read provider relationships that their own provider belongs to" do
      assert @dispatcher.can?(:read, @provider_relationship_1)
      assert @dispatcher.cannot?(:read, @provider_relationship_2)
      assert @dispatcher.can?(:read, @provider_relationship_3)
    end
    
    it "cannot update provider relationships regardless of the provider" do
      assert @dispatcher.cannot?(:update, @provider_relationship_1)    
      assert @dispatcher.cannot?(:update, @provider_relationship_2)
      assert @dispatcher.cannot?(:update, @provider_relationship_3)
    end
    
    it "cannot destroy provider relationships regardless of the provider" do
      assert @dispatcher.cannot?(:destroy, @provider_relationship_1)
      assert @dispatcher.cannot?(:destroy, @provider_relationship_2)
      assert @dispatcher.cannot?(:destroy, @provider_relationship_3)
    end
    
    it "cannot activate (aka approve) provider relationships regardless of the provider" do
      assert @dispatcher.cannot?(:activate, @provider_relationship_1)
      assert @dispatcher.cannot?(:activate, @provider_relationship_2)
      assert @dispatcher.cannot?(:activate, @provider_relationship_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of provider relationships that their own provider belongs to" do
      accessible = ProviderRelationship.accessible_by(@read_only)
      accessible.must_include @provider_relationship_1
      accessible.wont_include @provider_relationship_2
      accessible.must_include @provider_relationship_3
    end
    
    it "cannot create provider relationships regardless of the provider" do    
      assert @read_only.cannot?(:create, ProviderRelationship.new)
      assert @read_only.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_1.id))
      assert @read_only.cannot?(:create, ProviderRelationship.new(:requesting_provider_id => @provider_2.id))
      assert @read_only.cannot?(:create, ProviderRelationship.new(:cooperating_provider_id => @provider_1.id))
    end
    
    it "can read provider relationships that their own provider belongs to" do
      assert @read_only.can?(:read, @provider_relationship_1)
      assert @read_only.cannot?(:read, @provider_relationship_2)
      assert @read_only.can?(:read, @provider_relationship_3)
    end
    
    it "cannot update provider relationships regardless of the provider" do
      assert @read_only.cannot?(:update, @provider_relationship_1)    
      assert @read_only.cannot?(:update, @provider_relationship_2)
      assert @read_only.cannot?(:update, @provider_relationship_3)
    end
    
    it "cannot destroy provider relationships regardless of the provider" do
      assert @read_only.cannot?(:destroy, @provider_relationship_1)
      assert @read_only.cannot?(:destroy, @provider_relationship_2)
      assert @read_only.cannot?(:destroy, @provider_relationship_3)
    end
    
    it "cannot activate (aka approve) provider relationships regardless of the provider" do
      assert @read_only.cannot?(:activate, @provider_relationship_1)
      assert @read_only.cannot?(:activate, @provider_relationship_2)
      assert @read_only.cannot?(:activate, @provider_relationship_3)
    end
  end
end
