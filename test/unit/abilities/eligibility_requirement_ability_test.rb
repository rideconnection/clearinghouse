require 'test_helper'

class EligibilityRequirementAbilityTest < ActiveSupport::TestCase
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

    @er_1 = FactoryGirl.create(:eligibility_requirement, :service => @service_1)
    @er_2 = FactoryGirl.create(:eligibility_requirement, :service => @service_2)
    @er_3 = FactoryGirl.create(:eligibility_requirement, :service => @service_3)
  end

  # Provider admins and above can manage eligibility requirements belonging to their own provider's services

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of eligibility requirements belonging to their own provider's services" do
      accessible = EligibilityRequirement.accessible_by(@site_admin)
      accessible.must_include @er_1
      accessible.must_include @er_2
      accessible.wont_include @er_3
    end

    it "can create eligibility requirements belonging to their own provider's services" do
      assert @site_admin.cannot?(:create, EligibilityRequirement.new)
      assert @site_admin.can?(:create, @service_1.eligibility_requirements.build)
      assert @site_admin.can?(:create, @service_2.eligibility_requirements.build)
      assert @site_admin.cannot?(:create, @service_3.eligibility_requirements.build)
    end

    it "can read eligibility requirements belonging to their own provider's services" do
      assert @site_admin.can?(:read, @er_1)
      assert @site_admin.can?(:read, @er_2)
      assert @site_admin.cannot?(:read, @er_3)
    end

    it "can update eligibility requirements belonging to their own provider's services" do
      assert @site_admin.can?(:update, @er_1)
      assert @site_admin.can?(:update, @er_2)
      assert @site_admin.cannot?(:update, @er_3)
    end

    it "can destroy eligibility requirements belonging to their own provider's services" do
      assert @site_admin.can?(:destroy, @er_1)
      assert @site_admin.can?(:destroy, @er_2)
      assert @site_admin.cannot?(:destroy, @er_3)
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of eligibility requirements belonging to their own provider's services" do
      accessible = EligibilityRequirement.accessible_by(@provider_admin)
      accessible.must_include @er_1
      accessible.must_include @er_2
      accessible.wont_include @er_3
    end

    it "can create eligibility requirements belonging to their own provider's services" do
      assert @provider_admin.cannot?(:create, EligibilityRequirement.new)
      assert @provider_admin.can?(:create, @service_1.eligibility_requirements.build)
      assert @provider_admin.can?(:create, @service_2.eligibility_requirements.build)
      assert @provider_admin.cannot?(:create, @service_3.eligibility_requirements.build)
    end

    it "can read eligibility requirements belonging to their own provider's services" do
      assert @provider_admin.can?(:read, @er_1)
      assert @provider_admin.can?(:read, @er_2)
      assert @provider_admin.cannot?(:read, @er_3)
    end

    it "can update eligibility requirements belonging to their own provider's services" do
      assert @provider_admin.can?(:update, @er_1)
      assert @provider_admin.can?(:update, @er_2)
      assert @provider_admin.cannot?(:update, @er_3)
    end

    it "can destroy eligibility requirements belonging to their own provider's services" do
      assert @provider_admin.can?(:destroy, @er_1)
      assert @provider_admin.can?(:destroy, @er_2)
      assert @provider_admin.cannot?(:destroy, @er_3)
    end
  end

  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any eligibility requirements regardless of service provider" do
      accessible = EligibilityRequirement.accessible_by(@scheduler)
      accessible.wont_include @er_1
      accessible.wont_include @er_2
      accessible.wont_include @er_3
    end

    it "cannot create eligibility requirements regardless of service provider" do
      assert @scheduler.cannot?(:create, EligibilityRequirement.new)
      assert @scheduler.cannot?(:create, @service_1.eligibility_requirements.build)
      assert @scheduler.cannot?(:create, @service_2.eligibility_requirements.build)
      assert @scheduler.cannot?(:create, @service_3.eligibility_requirements.build)
    end

    it "cannot read eligibility requirements regardless of service provider" do
      assert @scheduler.cannot?(:read, @er_1)
      assert @scheduler.cannot?(:read, @er_2)
      assert @scheduler.cannot?(:read, @er_3)
    end

    it "cannot update eligibility requirements regardless of service provider" do
      assert @scheduler.cannot?(:update, @er_1)
      assert @scheduler.cannot?(:update, @er_2)
      assert @scheduler.cannot?(:update, @er_3)
    end

    it "cannot destroy eligibility requirements regardless of service provider" do
      assert @scheduler.cannot?(:destroy, @er_1)
      assert @scheduler.cannot?(:destroy, @er_2)
      assert @scheduler.cannot?(:destroy, @er_3)
    end
  end

  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any eligibility requirements regardless of service provider" do
      accessible = EligibilityRequirement.accessible_by(@dispatcher)
      accessible.wont_include @er_1
      accessible.wont_include @er_2
      accessible.wont_include @er_3
    end

    it "cannot create eligibility requirements regardless of service provider" do
      assert @dispatcher.cannot?(:create, EligibilityRequirement.new)
      assert @dispatcher.cannot?(:create, @service_1.eligibility_requirements.build)
      assert @dispatcher.cannot?(:create, @service_2.eligibility_requirements.build)
      assert @dispatcher.cannot?(:create, @service_3.eligibility_requirements.build)
    end

    it "cannot read eligibility requirements regardless of service provider" do
      assert @dispatcher.cannot?(:read, @er_1)
      assert @dispatcher.cannot?(:read, @er_2)
      assert @dispatcher.cannot?(:read, @er_3)
    end

    it "cannot update eligibility requirements regardless of service provider" do
      assert @dispatcher.cannot?(:update, @er_1)
      assert @dispatcher.cannot?(:update, @er_2)
      assert @dispatcher.cannot?(:update, @er_3)
    end

    it "cannot destroy eligibility requirements regardless of service provider" do
      assert @dispatcher.cannot?(:destroy, @er_1)
      assert @dispatcher.cannot?(:destroy, @er_2)
      assert @dispatcher.cannot?(:destroy, @er_3)
    end
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end

    it "cannot use accessible_by to load a list of any eligibility requirements regardless of service provider" do
      accessible = EligibilityRequirement.accessible_by(@read_only)
      accessible.wont_include @er_1
      accessible.wont_include @er_2
      accessible.wont_include @er_3
    end

    it "cannot create eligibility requirements regardless of service provider" do
      assert @read_only.cannot?(:create, EligibilityRequirement.new)
      assert @read_only.cannot?(:create, @service_1.eligibility_requirements.build)
      assert @read_only.cannot?(:create, @service_2.eligibility_requirements.build)
      assert @read_only.cannot?(:create, @service_3.eligibility_requirements.build)
    end

    it "cannot read eligibility requirements regardless of service provider" do
      assert @read_only.cannot?(:read, @er_1)
      assert @read_only.cannot?(:read, @er_2)
      assert @read_only.cannot?(:read, @er_3)
    end

    it "cannot update eligibility requirements regardless of service provider" do
      assert @read_only.cannot?(:update, @er_1)
      assert @read_only.cannot?(:update, @er_2)
      assert @read_only.cannot?(:update, @er_3)
    end

    it "cannot destroy eligibility requirements regardless of service provider" do
      assert @read_only.cannot?(:destroy, @er_1)
      assert @read_only.cannot?(:destroy, @er_2)
      assert @read_only.cannot?(:destroy, @er_3)
    end
  end
end
