require 'test_helper'

class ProviderRelationshipTest < ActiveSupport::TestCase
  setup do
    @provider_1 = FactoryGirl.create(:provider, :name => "Microsoft")
    @provider_2 = FactoryGirl.create(:provider, :name => "Google")
    @alternate_provider = FactoryGirl.create(:provider)
    @user = FactoryGirl.create(:user)
    @relationship = ProviderRelationship.create!(
      :requesting_provider => @provider_1,
      :cooperating_provider => @provider_2
    )
  end

  teardown do
    User.destroy_all
    Provider.destroy_all
    ProviderRelationship.destroy_all
  end

  describe "ProviderRelationship class" do
    it "can test if a relationship exists between two providers" do
      ProviderRelationship.relationship_exists?(@provider_1, @provider_2).must_equal true
      ProviderRelationship.relationship_exists?(@provider_2, @provider_1).must_equal true
      ProviderRelationship.relationship_exists?(@provider_1, @alternate_provider).must_equal false
      ProviderRelationship.relationship_exists?(@provider_2, @alternate_provider).must_equal false
    end
    
    it "can return an array of partner provider ids for a given provider" do
      partners = ProviderRelationship.partner_ids_for_provider(@provider_1)
      partners.must_include @provider_2.id
      partners.wont_include @alternate_provider.id

      ProviderRelationship.partner_ids_for_provider(@alternate_provider).must_equal []
    end
    
    it "can return an array of partner providers for a given provider" do
      partners = ProviderRelationship.partners_for_provider(@provider_1)
      partners.must_include @provider_2
      partners.wont_include @alternate_provider

      ProviderRelationship.partners_for_provider(@alternate_provider).must_equal []
    end
  end
  
  describe "A provider relationship" do
    it "cannot reference itself" do
      assert @relationship.valid?
      @relationship.cooperating_provider = @relationship.requesting_provider
      assert !@relationship.valid?
    end

    it "can't reference the same providers as an existing one" do
      relationship = ProviderRelationship.new(
        :requesting_provider => @provider_1,
        :cooperating_provider => @provider_2
      )
      assert !relationship.valid?
    end

    it "knows its name" do
      assert_equal @relationship.name, "Partnership between Microsoft and Google" 
    end

    it "can become approved" do
      assert !@relationship.approved?
      @relationship.approve!
      assert @relationship.approved?
    end

    it "knows whether it includes a given user" do
      @user.provider = @alternate_provider 
      assert !@relationship.includes_user?(@user)

      @user.provider = @provider_1 
      assert @relationship.includes_user?(@user)

      @user.provider = @provider_2 
      assert @relationship.includes_user?(@user)
    end 

    it "knows the corresponding partner when given a single partner" do
      assert_equal @relationship.partner_for_provider(@provider_1), @provider_2
      assert_equal @relationship.partner_for_provider(@provider_2), @provider_1
      assert_equal @relationship.partner_for_provider(@alternate_provider), nil
    end
  end
end
