require 'test_helper'

class OpenCapacityAbilityTest < ActiveSupport::TestCase
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

    @service_1 = FactoryGirl.create(:service, :provider => @provider_1)
    @service_2 = FactoryGirl.create(:service, :provider => @provider_2)
    @service_3 = FactoryGirl.create(:service, :provider => @provider_3)
    
    @open_cap_1 = FactoryGirl.create(:open_capacity, :service => @service_1)
    @open_cap_2 = FactoryGirl.create(:open_capacity, :service => @service_2)
    @open_cap_3 = FactoryGirl.create(:open_capacity, :service => @service_3)
    
    # All users can read open capacities that belonging to their own provider or providers they have an approved relationship with
    # Dispatchers and above can edit/cancel open capacity belonging to their own provider
    # Schedulers and above can create open capacities belonging to their own provider
    # No user can destroy open capacities    
  end
  
  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of open capacities that belonging to their own provider or providers they have an approved relationship with" do
      accessible = OpenCapacity.accessible_by(@site_admin)
      accessible.must_include @open_cap_1
      accessible.must_include @open_cap_2
      accessible.wont_include @open_cap_3
    end
  
    it "can create open capacities belonging to their own provider" do        
      assert @site_admin.cannot?(:create, OpenCapacity.new)
      assert @site_admin.can?(:create, OpenCapacity.new(:service_id => @service_1.id))
      assert @site_admin.cannot?(:create, OpenCapacity.new(:service_id => @service_2.id))
      assert @site_admin.cannot?(:create, OpenCapacity.new(:service_id => @service_3.id))
    end
  
    it "can read open capacities that belonging to their own provider or providers they have an approved relationship with" do
      assert @site_admin.can?(:read, @open_cap_1)
      assert @site_admin.can?(:read, @open_cap_2)
      assert @site_admin.cannot?(:read, @open_cap_3)
    end
  
    it "can update open capacity belonging to their own provider" do
      assert @site_admin.can?(:update, @open_cap_1)
      assert @site_admin.cannot?(:update, @open_cap_2)
      assert @site_admin.cannot?(:update, @open_cap_3)
    end
  
    it "cannot destroy services regardless of the provider" do
      assert @site_admin.cannot?(:destroy, @open_cap_1)
      assert @site_admin.cannot?(:destroy, @open_cap_2)
      assert @site_admin.cannot?(:destroy, @open_cap_3)
    end
  end
  
  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of open capacities that belonging to their own provider or providers they have an approved relationship with" do
      accessible = OpenCapacity.accessible_by(@provider_admin)
      accessible.must_include @open_cap_1
      accessible.must_include @open_cap_2
      accessible.wont_include @open_cap_3
    end
  
    it "can create open capacities belonging to their own provider" do        
      assert @provider_admin.cannot?(:create, OpenCapacity.new)
      assert @provider_admin.can?(:create, OpenCapacity.new(:service_id => @service_1.id))
      assert @provider_admin.cannot?(:create, OpenCapacity.new(:service_id => @service_2.id))
      assert @provider_admin.cannot?(:create, OpenCapacity.new(:service_id => @service_3.id))
    end
  
    it "can read open capacities that belonging to their own provider or providers they have an approved relationship with" do
      assert @provider_admin.can?(:read, @open_cap_1)
      assert @provider_admin.can?(:read, @open_cap_2)
      assert @provider_admin.cannot?(:read, @open_cap_3)
    end
  
    it "can update open capacity belonging to their own provider" do
      assert @provider_admin.can?(:update, @open_cap_1)
      assert @provider_admin.cannot?(:update, @open_cap_2)
      assert @provider_admin.cannot?(:update, @open_cap_3)
    end
  
    it "cannot destroy services regardless of the provider" do
      assert @provider_admin.cannot?(:destroy, @open_cap_1)
      assert @provider_admin.cannot?(:destroy, @open_cap_2)
      assert @provider_admin.cannot?(:destroy, @open_cap_3)
    end
  end
  
  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of open capacities that belonging to their own provider or providers they have an approved relationship with" do
      accessible = OpenCapacity.accessible_by(@scheduler)
      accessible.must_include @open_cap_1
      accessible.must_include @open_cap_2
      accessible.wont_include @open_cap_3
    end
  
    it "can create open capacities belonging to their own provider" do        
      assert @scheduler.cannot?(:create, OpenCapacity.new)
      assert @scheduler.can?(:create, OpenCapacity.new(:service_id => @service_1.id))
      assert @scheduler.cannot?(:create, OpenCapacity.new(:service_id => @service_2.id))
      assert @scheduler.cannot?(:create, OpenCapacity.new(:service_id => @service_3.id))
    end
  
    it "can read open capacities that belonging to their own provider or providers they have an approved relationship with" do
      assert @scheduler.can?(:read, @open_cap_1)
      assert @scheduler.can?(:read, @open_cap_2)
      assert @scheduler.cannot?(:read, @open_cap_3)
    end
  
    it "can update open capacity belonging to their own provider" do
      assert @scheduler.can?(:update, @open_cap_1)
      assert @scheduler.cannot?(:update, @open_cap_2)
      assert @scheduler.cannot?(:update, @open_cap_3)
    end
  
    it "cannot destroy services regardless of the provider" do
      assert @scheduler.cannot?(:destroy, @open_cap_1)
      assert @scheduler.cannot?(:destroy, @open_cap_2)
      assert @scheduler.cannot?(:destroy, @open_cap_3)
    end
  end
  
  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of open capacities that belonging to their own provider or providers they have an approved relationship with" do
      accessible = OpenCapacity.accessible_by(@dispatcher)
      accessible.must_include @open_cap_1
      accessible.must_include @open_cap_2
      accessible.wont_include @open_cap_3
    end
  
    it "cannot create open capacities regardless of their own provider" do        
      assert @dispatcher.cannot?(:create, OpenCapacity.new)
      assert @dispatcher.cannot?(:create, OpenCapacity.new(:service_id => @service_1.id))
      assert @dispatcher.cannot?(:create, OpenCapacity.new(:service_id => @service_2.id))
      assert @dispatcher.cannot?(:create, OpenCapacity.new(:service_id => @service_3.id))
    end
  
    it "can read open capacities that belonging to their own provider or providers they have an approved relationship with" do
      assert @dispatcher.can?(:read, @open_cap_1)
      assert @dispatcher.can?(:read, @open_cap_2)
      assert @dispatcher.cannot?(:read, @open_cap_3)
    end
  
    it "can update open capacity belonging to their own provider" do
      assert @dispatcher.can?(:update, @open_cap_1)
      assert @dispatcher.cannot?(:update, @open_cap_2)
      assert @dispatcher.cannot?(:update, @open_cap_3)
    end
  
    it "cannot destroy services regardless of the provider" do
      assert @dispatcher.cannot?(:destroy, @open_cap_1)
      assert @dispatcher.cannot?(:destroy, @open_cap_2)
      assert @dispatcher.cannot?(:destroy, @open_cap_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of open capacities that belonging to their own provider or providers they have an approved relationship with" do
      accessible = OpenCapacity.accessible_by(@read_only)
      accessible.must_include @open_cap_1
      accessible.must_include @open_cap_2
      accessible.wont_include @open_cap_3
    end
  
    it "cannot create open capacities regardless of their own provider" do        
      assert @read_only.cannot?(:create, OpenCapacity.new)
      assert @read_only.cannot?(:create, OpenCapacity.new(:service_id => @service_1.id))
      assert @read_only.cannot?(:create, OpenCapacity.new(:service_id => @service_2.id))
      assert @read_only.cannot?(:create, OpenCapacity.new(:service_id => @service_3.id))
    end
  
    it "can read open capacities that belonging to their own provider or providers they have an approved relationship with" do
      assert @read_only.can?(:read, @open_cap_1)
      assert @read_only.can?(:read, @open_cap_2)
      assert @read_only.cannot?(:read, @open_cap_3)
    end
  
    it "cannot update open capacity regardless of their own provider" do
      assert @read_only.cannot?(:update, @open_cap_1)
      assert @read_only.cannot?(:update, @open_cap_2)
      assert @read_only.cannot?(:update, @open_cap_3)
    end
  
    it "cannot destroy services regardless of the provider" do
      assert @read_only.cannot?(:destroy, @open_cap_1)
      assert @read_only.cannot?(:destroy, @open_cap_2)
      assert @read_only.cannot?(:destroy, @open_cap_3)
    end
  end
end
