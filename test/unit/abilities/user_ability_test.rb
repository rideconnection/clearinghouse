require 'test_helper'

class UserAbilityTest < ActiveSupport::TestCase
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

    @user_1 = FactoryGirl.create(:user, :provider => @provider_1)
    @user_2 = FactoryGirl.create(:user, :provider => @provider_2)

    # All users can read users belonging to their own provider
    # All users can update their own profile
    # Provider admins can create, update and deactivate users belonging to their own provider
    # No user can deactivate themselves
    # No user can destroy users
  end

  describe "site_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:site_admin]
      @site_admin = Ability.new(@current_user)
    end

    it "can use accessible_by to load a list of accessible resources" do
      accessible = User.accessible_by(@site_admin)
      accessible.must_include @current_user
      accessible.must_include @user_1
      accessible.must_include @user_2
    end

    it "can create users regardless of the user's provider" do
      assert @site_admin.can?(:create, User.new)
      assert @site_admin.can?(:create, User.new(:provider_id => @provider_1.id))
      assert @site_admin.can?(:create, User.new(:provider_id => @provider_2.id))
    end

    it "can read users regardless of the user's provider" do
      assert @site_admin.can?(:read, @user_1)
      assert @site_admin.can?(:read, @user_2)
    end

    it "can update users regardless of the user's provider" do
      assert @site_admin.can?(:update, @user_1)
      assert @site_admin.can?(:update, @user_2)
    end

    it "cannot destory any users" do
      assert @site_admin.cannot?(:destroy, @user_1)
      assert @site_admin.cannot?(:destroy, @user_2)
    end

    it "can activate users regardless of the user's provider" do
      assert @site_admin.can?(:activate, @user_1)
      assert @site_admin.can?(:activate, @user_2)
    end

    it "can deactivate users regardless of the user's provider" do
      assert @site_admin.can?(:deactivate, @user_1)
      assert @site_admin.can?(:deactivate, @user_2)
    end

    it "can set the provider role of all users regardless of the user's provider" do
      assert @site_admin.can?(:set_provider_role, @user_1)
      assert @site_admin.can?(:set_provider_role, @user_2)
    end

    describe "current user" do
      it "can read its own user record" do
        assert @site_admin.can?(:read, @current_user)
      end
    
      it "can update its own user record" do
        assert @site_admin.can?(:update, @current_user)
      end
    
      it "cannot destroy its own user record" do
        assert @site_admin.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @site_admin.cannot?(:deactivate, @current_user)
      end
    end
  end

  describe "provider_admin role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:provider_admin]
      @provider_admin = Ability.new(@current_user)
    end
  
    it "can use accessible_by to find users belonging to their own provider" do
      accessible = User.accessible_by(@provider_admin)
      accessible.must_include @current_user
      accessible.must_include @user_1
      accessible.wont_include @user_2
    end
  
    it "can create users belonging to their own provider" do  
      assert @provider_admin.cannot?(:create, User.new)
      assert @provider_admin.can?(:create, User.new(:provider_id => @provider_1.id))
      assert @provider_admin.cannot?(:create, User.new(:provider_id => @provider_2.id))
    end
  
    it "can read other users belonging to their own provider" do
      assert @provider_admin.can?(:read, @user_1)
      assert @provider_admin.cannot?(:read, @user_2)
    end
  
    it "can update users belonging to their own provider" do
      assert @provider_admin.can?(:update, @user_1)
      assert @provider_admin.cannot?(:update, @user_2)
    end
  
    it "cannot destroy any users regardless of provider" do
      assert @provider_admin.cannot?(:destroy, @user_1)
      assert @provider_admin.cannot?(:destroy, @user_2)
    end
  
    it "can activate users belonging to their own provider" do
      assert @provider_admin.can?(:activate, @user_1)
      assert @provider_admin.cannot?(:activate, @user_2)
    end
    
    it "can deactivate users belonging to their own provider" do
      assert @provider_admin.can?(:deactivate, @user_1)
      assert @provider_admin.cannot?(:deactivate, @user_2)
    end
    
    it "can set the role users belonging to their own provider" do
      assert @provider_admin.can?(:set_provider_role, @user_1)
      assert @provider_admin.cannot?(:set_provider_role, @user_2)
    end
  
    describe "current user" do
      it "can read its own user record" do
        assert @provider_admin.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @provider_admin.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @provider_admin.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @provider_admin.cannot?(:deactivate, @current_user)
      end
    end    
  end
  
  describe "scheduler role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:scheduler]
      @scheduler = Ability.new(@current_user)
    end
    
    it "can use accessible_by to find users belonging to their own provider" do
      accessible = User.accessible_by(@scheduler)
      accessible.must_include @current_user
      accessible.must_include @user_1
      accessible.wont_include @user_2
    end
  
    it "cannot create users regardless of their provider" do
      assert @scheduler.cannot?(:create, User.new)
      assert @scheduler.cannot?(:create, User.new(:provider_id => @provider_1.id))
      assert @scheduler.cannot?(:create, User.new(:provider_id => @provider_2.id))
    end
  
    it "can read other users belonging to their own provider" do
      assert @scheduler.can?(:read, @user_1)
      assert @scheduler.cannot?(:read, @user_2)
    end
  
    it "cannot update other users regardless of their provider" do
      assert @scheduler.cannot?(:update, @user_1)
      assert @scheduler.cannot?(:update, @user_2)
    end
  
    it "cannot destroy any users regardless of provider" do
      assert @scheduler.cannot?(:destroy, @user_1)
      assert @scheduler.cannot?(:destroy, @user_2)
    end
  
    it "cannot activate other users regardless of their provider" do
      assert @scheduler.cannot?(:activate, @user_1)
      assert @scheduler.cannot?(:activate, @user_2)
    end
    
    it "cannot deactivate other users regardless of their provider" do
      assert @scheduler.cannot?(:deactivate, @user_1)
      assert @scheduler.cannot?(:deactivate, @user_2)
    end
    
    it "cannot set the role of other users regardless of their provider" do
      assert @scheduler.cannot?(:set_provider_role, @user_1)
      assert @scheduler.cannot?(:set_provider_role, @user_2)
    end
  
    describe "current user" do
      it "can read its own user record" do
        assert @scheduler.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @scheduler.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @scheduler.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @scheduler.cannot?(:deactivate, @current_user)
      end
    end    
  end
  
  describe "dispatcher role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:dispatcher]
      @dispatcher = Ability.new(@current_user)
    end
    
    it "can use accessible_by to find users belonging to their own provider" do
      accessible = User.accessible_by(@dispatcher)
      accessible.must_include @current_user
      accessible.must_include @user_1
      accessible.wont_include @user_2
    end
  
    it "cannot create users regardless of their provider" do
      assert @dispatcher.cannot?(:create, User.new)
      assert @dispatcher.cannot?(:create, User.new(:provider_id => @provider_1.id))
      assert @dispatcher.cannot?(:create, User.new(:provider_id => @provider_2.id))
    end
  
    it "can read other users belonging to their own provider" do
      assert @dispatcher.can?(:read, @user_1)
      assert @dispatcher.cannot?(:read, @user_2)
    end
  
    it "cannot update other users regardless of their provider" do
      assert @dispatcher.cannot?(:update, @user_1)
      assert @dispatcher.cannot?(:update, @user_2)
    end
  
    it "cannot destroy any users regardless of provider" do
      assert @dispatcher.cannot?(:destroy, @user_1)
      assert @dispatcher.cannot?(:destroy, @user_2)
    end
  
    it "cannot activate other users regardless of their provider" do
      assert @dispatcher.cannot?(:activate, @user_1)
      assert @dispatcher.cannot?(:activate, @user_2)
    end
    
    it "cannot deactivate other users regardless of their provider" do
      assert @dispatcher.cannot?(:deactivate, @user_1)
      assert @dispatcher.cannot?(:deactivate, @user_2)
    end
    
    it "cannot set the role of other users regardless of their provider" do
      assert @dispatcher.cannot?(:set_provider_role, @user_1)
      assert @dispatcher.cannot?(:set_provider_role, @user_2)
    end
  
    describe "current user" do
      it "can read its own user record" do
        assert @dispatcher.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @dispatcher.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @dispatcher.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @dispatcher.cannot?(:deactivate, @current_user)
      end
    end    
  end

  describe "read_only role" do
    setup do
      @current_user = FactoryGirl.create(:user, :provider => @provider_1)
      @current_user.role = @roles[:read_only]
      @read_only = Ability.new(@current_user)
    end
    
    it "can use accessible_by to find users belonging to their own provider" do
      accessible = User.accessible_by(@read_only)
      accessible.must_include @current_user
      accessible.must_include @user_1
      accessible.wont_include @user_2
    end
  
    it "cannot create users regardless of their provider" do
      assert @read_only.cannot?(:create, User.new)
      assert @read_only.cannot?(:create, User.new(:provider_id => @provider_1.id))
      assert @read_only.cannot?(:create, User.new(:provider_id => @provider_2.id))
    end
  
    it "can read other users belonging to their own provider" do
      assert @read_only.can?(:read, @user_1)
      assert @read_only.cannot?(:read, @user_2)
    end
  
    it "cannot update other users regardless of their provider" do
      assert @read_only.cannot?(:update, @user_1)
      assert @read_only.cannot?(:update, @user_2)
    end
  
    it "cannot destroy any users regardless of provider" do
      assert @read_only.cannot?(:destroy, @user_1)
      assert @read_only.cannot?(:destroy, @user_2)
    end
  
    it "cannot activate other users regardless of their provider" do
      assert @read_only.cannot?(:activate, @user_1)
      assert @read_only.cannot?(:activate, @user_2)
    end
    
    it "cannot deactivate other users regardless of their provider" do
      assert @read_only.cannot?(:deactivate, @user_1)
      assert @read_only.cannot?(:deactivate, @user_2)
    end
    
    it "cannot set the role of other users regardless of their provider" do
      assert @read_only.cannot?(:set_provider_role, @user_1)
      assert @read_only.cannot?(:set_provider_role, @user_2)
    end
  
    describe "current user" do
      it "can read its own user record" do
        assert @read_only.can?(:read, @current_user)
      end
      
      it "can update its own user record" do
        assert @read_only.can?(:update, @current_user)
      end
      
      it "cannot destroy its own user record" do
        assert @read_only.cannot?(:destroy, @current_user)
      end
      
      it "cannot deactivate its own user record" do
        assert @read_only.cannot?(:deactivate, @current_user)
      end
    end
  end
end
