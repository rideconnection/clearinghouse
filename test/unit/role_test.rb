require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  setup do
    @site_admin = FactoryGirl.create(:role, :name => "site_admin")
    @other_role = FactoryGirl.create(:role, :name => "other_role")
  end
  
  teardown do
    @site_admin.destroy
    @other_role.destroy
  end
  
  describe "Role class" do
    it "knows if a given role is considered a site_admin role" do
      Role.is_admin_role?(@site_admin).must_equal true
      Role.is_admin_role?(@other_role).must_equal false
    end
    
    it "includes a scope that returns an array of roles that aren't site_admin roles" do
      provider_roles = Role.provider_roles
      provider_roles.must_include @other_role
      provider_roles.wont_include @site_admin
    end
  end
  
  describe "Role instance" do
    it "knows if it is considered a site_admin role" do
      @site_admin.is_admin_role?.must_equal true
      @other_role.is_admin_role?.must_equal false
    end
  end
end
