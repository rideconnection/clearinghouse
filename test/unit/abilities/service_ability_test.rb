require 'test_helper'

class ServiceAbilityTest < ActiveSupport::TestCase
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

    # All users can read services belonging to their own provider or providers they have an approved relationship with
    # Provider admins can create and update services belonging to their own provider
    # No user can destroy services
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of services belonging to their own provider or providers they have an approved relationship with" do
      accessible = Service.accessible_by(@site_admin)
      accessible.must_include @service_1
      accessible.must_include @service_2
      accessible.wont_include @service_3
    end

    it "can create services belonging to their own provider" do
      assert @site_admin.cannot?(:create, Service.new)
      assert @site_admin.can?(:create, Service.new(:provider_id => @provider_1.id))
      assert @site_admin.cannot?(:create, Service.new(:provider_id => @provider_2.id))
      assert @site_admin.cannot?(:create, Service.new(:provider_id => @provider_3.id))
    end

    it "can read services services belonging to their own provider or providers they have an approved relationship with" do
      assert @site_admin.can?(:read, @service_1)
      assert @site_admin.can?(:read, @service_2)
      assert @site_admin.cannot?(:read, @service_3)
    end

    it "can update services belonging to their own provider" do
      assert @site_admin.can?(:update, @service_1)
      assert @site_admin.cannot?(:update, @service_2)
      assert @site_admin.cannot?(:update, @service_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @site_admin.cannot?(:destroy, @service_1)
      assert @site_admin.cannot?(:destroy, @service_2)
      assert @site_admin.cannot?(:destroy, @service_3)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of services belonging to their own provider or providers they have an approved relationship with" do
      accessible = Service.accessible_by(@provider_admin)
      accessible.must_include @service_1
      accessible.must_include @service_2
      accessible.wont_include @service_3
    end

    it "can create services belonging to their own provider" do
      assert @provider_admin.cannot?(:create, Service.new)
      assert @provider_admin.can?(:create, Service.new(:provider_id => @provider_1.id))
      assert @provider_admin.cannot?(:create, Service.new(:provider_id => @provider_2.id))
      assert @provider_admin.cannot?(:create, Service.new(:provider_id => @provider_3.id))
    end

    it "can read services services belonging to their own provider or providers they have an approved relationship with" do
      assert @provider_admin.can?(:read, @service_1)
      assert @provider_admin.can?(:read, @service_2)
      assert @provider_admin.cannot?(:read, @service_3)
    end

    it "can update services belonging to their own provider" do
      assert @provider_admin.can?(:update, @service_1)
      assert @provider_admin.cannot?(:update, @service_2)
      assert @provider_admin.cannot?(:update, @service_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @provider_admin.cannot?(:destroy, @service_1)
      assert @provider_admin.cannot?(:destroy, @service_2)
      assert @provider_admin.cannot?(:destroy, @service_3)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of services belonging to their own provider or providers they have an approved relationship with" do
      accessible = Service.accessible_by(@scheduler)
      accessible.must_include @service_1
      accessible.must_include @service_2
      accessible.wont_include @service_3
    end

    it "cannot create services regardless of the provider" do
      assert @scheduler.cannot?(:create, Service.new)
      assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_1.id))
      assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_2.id))
      assert @scheduler.cannot?(:create, Service.new(:provider_id => @provider_3.id))
    end

    it "can read services services belonging to their own provider or providers they have an approved relationship with" do
      assert @scheduler.can?(:read, @service_1)
      assert @scheduler.can?(:read, @service_2)
      assert @scheduler.cannot?(:read, @service_3)
    end

    it "cannot update services regardless of the provider" do
      assert @scheduler.cannot?(:update, @service_1)
      assert @scheduler.cannot?(:update, @service_2)
      assert @scheduler.cannot?(:update, @service_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @scheduler.cannot?(:destroy, @service_1)
      assert @scheduler.cannot?(:destroy, @service_2)
      assert @scheduler.cannot?(:destroy, @service_3)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of services belonging to their own provider or providers they have an approved relationship with" do
      accessible = Service.accessible_by(@dispatcher)
      accessible.must_include @service_1
      accessible.must_include @service_2
      accessible.wont_include @service_3
    end

    it "cannot create services regardless of the provider" do
      assert @dispatcher.cannot?(:create, Service.new)
      assert @dispatcher.cannot?(:create, Service.new(:provider_id => @provider_1.id))
      assert @dispatcher.cannot?(:create, Service.new(:provider_id => @provider_2.id))
      assert @dispatcher.cannot?(:create, Service.new(:provider_id => @provider_3.id))
    end

    it "can read services services belonging to their own provider or providers they have an approved relationship with" do
      assert @dispatcher.can?(:read, @service_1)
      assert @dispatcher.can?(:read, @service_2)
      assert @dispatcher.cannot?(:read, @service_3)
    end

    it "cannot update services regardless of the provider" do
      assert @dispatcher.cannot?(:update, @service_1)
      assert @dispatcher.cannot?(:update, @service_2)
      assert @dispatcher.cannot?(:update, @service_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @dispatcher.cannot?(:destroy, @service_1)
      assert @dispatcher.cannot?(:destroy, @service_2)
      assert @dispatcher.cannot?(:destroy, @service_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of services belonging to their own provider or providers they have an approved relationship with" do
      accessible = Service.accessible_by(@read_only)
      accessible.must_include @service_1
      accessible.must_include @service_2
      accessible.wont_include @service_3
    end

    it "cannot create services regardless of the provider" do
      assert @read_only.cannot?(:create, Service.new)
      assert @read_only.cannot?(:create, Service.new(:provider_id => @provider_1.id))
      assert @read_only.cannot?(:create, Service.new(:provider_id => @provider_2.id))
      assert @read_only.cannot?(:create, Service.new(:provider_id => @provider_3.id))
    end

    it "can read services services belonging to their own provider or providers they have an approved relationship with" do
      assert @read_only.can?(:read, @service_1)
      assert @read_only.can?(:read, @service_2)
      assert @read_only.cannot?(:read, @service_3)
    end

    it "cannot update services regardless of the provider" do
      assert @read_only.cannot?(:update, @service_1)
      assert @read_only.cannot?(:update, @service_2)
      assert @read_only.cannot?(:update, @service_3)
    end

    it "cannot destroy services regardless of the provider" do
      assert @read_only.cannot?(:destroy, @service_1)
      assert @read_only.cannot?(:destroy, @service_2)
      assert @read_only.cannot?(:destroy, @service_3)
    end
  end
end
