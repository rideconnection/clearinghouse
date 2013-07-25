require 'test_helper'

class MobilityAccommodationAbilityTest < ActiveSupport::TestCase
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

    @service_1 = FactoryGirl.create(:service, :provider => @provider_1)
    @service_2 = FactoryGirl.create(:service, :provider => @provider_1)
    @service_3 = FactoryGirl.create(:service, :provider => @provider_2)

    @ma_1 = FactoryGirl.create(:mobility_accommodation, :service => @service_1)
    @ma_2 = FactoryGirl.create(:mobility_accommodation, :service => @service_2)
    @ma_3 = FactoryGirl.create(:mobility_accommodation, :service => @service_3)
  end

  # Provider admins and above can manage mobility accommodations belonging to their own provider's services

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of mobility accommodations belonging to their own provider's services" do
      accessible = MobilityAccommodation.accessible_by(@site_admin)
      accessible.must_include @ma_1
      accessible.must_include @ma_2
      accessible.wont_include @ma_3
    end

    it "can create mobility accommodations belonging to their own provider's services" do
      assert @site_admin.cannot?(:create, MobilityAccommodation.new)
      assert @site_admin.can?(:create, @service_1.mobility_accommodations.build)
      assert @site_admin.can?(:create, @service_2.mobility_accommodations.build)
      assert @site_admin.cannot?(:create, @service_3.mobility_accommodations.build)
    end

    it "can read mobility accommodations belonging to their own provider's services" do
      assert @site_admin.can?(:read, @ma_1)
      assert @site_admin.can?(:read, @ma_2)
      assert @site_admin.cannot?(:read, @ma_3)
    end

    it "can update mobility accommodations belonging to their own provider's services" do
      assert @site_admin.can?(:update, @ma_1)
      assert @site_admin.can?(:update, @ma_2)
      assert @site_admin.cannot?(:update, @ma_3)
    end

    it "can destroy mobility accommodations belonging to their own provider's services" do
      assert @site_admin.can?(:destroy, @ma_1)
      assert @site_admin.can?(:destroy, @ma_2)
      assert @site_admin.cannot?(:destroy, @ma_3)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of mobility accommodations belonging to their own provider's services" do
      accessible = MobilityAccommodation.accessible_by(@provider_admin)
      accessible.must_include @ma_1
      accessible.must_include @ma_2
      accessible.wont_include @ma_3
    end

    it "can create mobility accommodations belonging to their own provider's services" do
      assert @provider_admin.cannot?(:create, MobilityAccommodation.new)
      assert @provider_admin.can?(:create, @service_1.mobility_accommodations.build)
      assert @provider_admin.can?(:create, @service_2.mobility_accommodations.build)
      assert @provider_admin.cannot?(:create, @service_3.mobility_accommodations.build)
    end

    it "can read mobility accommodations belonging to their own provider's services" do
      assert @provider_admin.can?(:read, @ma_1)
      assert @provider_admin.can?(:read, @ma_2)
      assert @provider_admin.cannot?(:read, @ma_3)
    end

    it "can update mobility accommodations belonging to their own provider's services" do
      assert @provider_admin.can?(:update, @ma_1)
      assert @provider_admin.can?(:update, @ma_2)
      assert @provider_admin.cannot?(:update, @ma_3)
    end

    it "can destroy mobility accommodations belonging to their own provider's services" do
      assert @provider_admin.can?(:destroy, @ma_1)
      assert @provider_admin.can?(:destroy, @ma_2)
      assert @provider_admin.cannot?(:destroy, @ma_3)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any mobility accommodations regardless of service provider" do
      accessible = MobilityAccommodation.accessible_by(@scheduler)
      accessible.wont_include @ma_1
      accessible.wont_include @ma_2
      accessible.wont_include @ma_3
    end

    it "cannot create mobility accommodations regardless of service provider" do
      assert @scheduler.cannot?(:create, MobilityAccommodation.new)
      assert @scheduler.cannot?(:create, @service_1.mobility_accommodations.build)
      assert @scheduler.cannot?(:create, @service_2.mobility_accommodations.build)
      assert @scheduler.cannot?(:create, @service_3.mobility_accommodations.build)
    end

    it "cannot read mobility accommodations regardless of service provider" do
      assert @scheduler.cannot?(:read, @ma_1)
      assert @scheduler.cannot?(:read, @ma_2)
      assert @scheduler.cannot?(:read, @ma_3)
    end

    it "cannot update mobility accommodations regardless of service provider" do
      assert @scheduler.cannot?(:update, @ma_1)
      assert @scheduler.cannot?(:update, @ma_2)
      assert @scheduler.cannot?(:update, @ma_3)
    end

    it "cannot destroy mobility accommodations regardless of service provider" do
      assert @scheduler.cannot?(:destroy, @ma_1)
      assert @scheduler.cannot?(:destroy, @ma_2)
      assert @scheduler.cannot?(:destroy, @ma_3)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any mobility accommodations regardless of service provider" do
      accessible = MobilityAccommodation.accessible_by(@dispatcher)
      accessible.wont_include @ma_1
      accessible.wont_include @ma_2
      accessible.wont_include @ma_3
    end

    it "cannot create mobility accommodations regardless of service provider" do
      assert @dispatcher.cannot?(:create, MobilityAccommodation.new)
      assert @dispatcher.cannot?(:create, @service_1.mobility_accommodations.build)
      assert @dispatcher.cannot?(:create, @service_2.mobility_accommodations.build)
      assert @dispatcher.cannot?(:create, @service_3.mobility_accommodations.build)
    end

    it "cannot read mobility accommodations regardless of service provider" do
      assert @dispatcher.cannot?(:read, @ma_1)
      assert @dispatcher.cannot?(:read, @ma_2)
      assert @dispatcher.cannot?(:read, @ma_3)
    end

    it "cannot update mobility accommodations regardless of service provider" do
      assert @dispatcher.cannot?(:update, @ma_1)
      assert @dispatcher.cannot?(:update, @ma_2)
      assert @dispatcher.cannot?(:update, @ma_3)
    end

    it "cannot destroy mobility accommodations regardless of service provider" do
      assert @dispatcher.cannot?(:destroy, @ma_1)
      assert @dispatcher.cannot?(:destroy, @ma_2)
      assert @dispatcher.cannot?(:destroy, @ma_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any mobility accommodations regardless of service provider" do
      accessible = MobilityAccommodation.accessible_by(@read_only)
      accessible.wont_include @ma_1
      accessible.wont_include @ma_2
      accessible.wont_include @ma_3
    end

    it "cannot create mobility accommodations regardless of service provider" do
      assert @read_only.cannot?(:create, MobilityAccommodation.new)
      assert @read_only.cannot?(:create, @service_1.mobility_accommodations.build)
      assert @read_only.cannot?(:create, @service_2.mobility_accommodations.build)
      assert @read_only.cannot?(:create, @service_3.mobility_accommodations.build)
    end

    it "cannot read mobility accommodations regardless of service provider" do
      assert @read_only.cannot?(:read, @ma_1)
      assert @read_only.cannot?(:read, @ma_2)
      assert @read_only.cannot?(:read, @ma_3)
    end

    it "cannot update mobility accommodations regardless of service provider" do
      assert @read_only.cannot?(:update, @ma_1)
      assert @read_only.cannot?(:update, @ma_2)
      assert @read_only.cannot?(:update, @ma_3)
    end

    it "cannot destroy mobility accommodations regardless of service provider" do
      assert @read_only.cannot?(:destroy, @ma_1)
      assert @read_only.cannot?(:destroy, @ma_2)
      assert @read_only.cannot?(:destroy, @ma_3)
    end
  end
end
