require 'test_helper'

class ProviderRelationshipTest < ActiveSupport::TestCase
  setup do
    @provider_1 = FactoryGirl.create(:provider, :name => "Microsoft")
    @provider_2 = FactoryGirl.create(:provider, :name => "Google")
    @provider_3 = FactoryGirl.create(:provider, :name => "Yahoo")
    @alternate_provider = FactoryGirl.create(:provider)
    @user = FactoryGirl.create(:user)
    @relationship_1 = ProviderRelationship.create!(
      :requesting_provider => @provider_1,
      :cooperating_provider => @provider_2
    )
    @relationship_1.approve!
    @relationship_2 = ProviderRelationship.create!(
      :requesting_provider => @provider_1,
      :cooperating_provider => @provider_3
    )    
  end

  teardown do
    User.destroy_all
    Provider.destroy_all
    ProviderRelationship.destroy_all
  end

  describe "ProviderRelationship class" do
    it "can test if a relationship exists between two providers, approved or not" do
      ProviderRelationship.relationship_exists?(@provider_1, @provider_2).must_equal true
      ProviderRelationship.relationship_exists?(@provider_2, @provider_1).must_equal true
      ProviderRelationship.relationship_exists?(@provider_1, @provider_3).must_equal true
      ProviderRelationship.relationship_exists?(@provider_3, @provider_1).must_equal true

      ProviderRelationship.relationship_exists?(@provider_2, @provider_3).must_equal false
      ProviderRelationship.relationship_exists?(@provider_1, @alternate_provider).must_equal false
      ProviderRelationship.relationship_exists?(@provider_2, @alternate_provider).must_equal false
    end
    
    it "can return an array of approved partner provider ids for a given provider" do
      partners = ProviderRelationship.partner_ids_for_provider(@provider_1)
      partners.must_include @provider_2.id
      partners.wont_include @provider_3.id
      partners.wont_include @alternate_provider.id

      ProviderRelationship.partner_ids_for_provider(@provider_3).must_equal []
      ProviderRelationship.partner_ids_for_provider(@alternate_provider).must_equal []
    end
    
    it "can find an approved relationship between two providers" do
      assert_equal @relationship_1, ProviderRelationship.find_approved_relationship_between(@provider_1, @provider_2)
      assert_equal @relationship_1, ProviderRelationship.find_approved_relationship_between(@provider_2, @provider_1)

      assert_nil ProviderRelationship.find_approved_relationship_between(@provider_1, @provider_3)
      assert_nil ProviderRelationship.find_approved_relationship_between(@provider_2, @provider_3)
      assert_nil ProviderRelationship.find_approved_relationship_between(@provider_1, @alternate_provider)
      assert_nil ProviderRelationship.find_approved_relationship_between(@provider_2, @alternate_provider)
    end
    
    it "can find any relationship between two providers" do
      assert_equal @relationship_1, ProviderRelationship.find_any_relationship_between(@provider_1, @provider_2)
      assert_equal @relationship_1, ProviderRelationship.find_any_relationship_between(@provider_2, @provider_1)
      assert_equal @relationship_2, ProviderRelationship.find_any_relationship_between(@provider_1, @provider_3)
      assert_equal @relationship_2, ProviderRelationship.find_any_relationship_between(@provider_3, @provider_1)

      assert_nil ProviderRelationship.find_any_relationship_between(@provider_2, @provider_3)
      assert_nil ProviderRelationship.find_any_relationship_between(@provider_1, @alternate_provider)
      assert_nil ProviderRelationship.find_any_relationship_between(@provider_2, @alternate_provider)
    end
  end
  
  describe "A provider relationship" do
    it "cannot reference itself" do
      assert @relationship_1.valid?
      @relationship_1.cooperating_provider = @relationship_1.requesting_provider
      assert !@relationship_1.valid?
    end

    it "can't reference the same providers as an existing one" do
      relationship = ProviderRelationship.new(
        :requesting_provider => @provider_1,
        :cooperating_provider => @provider_2
      )
      assert !relationship.valid?
    end

    it "knows its name" do
      assert_equal @relationship_1.name, "Partnership between Microsoft and Google" 
    end

    it "can become approved" do
      assert !@relationship_2.approved?
      @relationship_2.approve!
      assert @relationship_2.approved?
    end

    it "knows whether it includes a given user" do
      @user.provider = @alternate_provider 
      assert !@relationship_1.includes_user?(@user)

      @user.provider = @provider_1 
      assert @relationship_1.includes_user?(@user)

      @user.provider = @provider_2 
      assert @relationship_1.includes_user?(@user)
    end 

    it "knows the corresponding partner when given a single partner" do
      assert_equal @relationship_1.partner_for_provider(@provider_1), @provider_2
      assert_equal @relationship_1.partner_for_provider(@provider_2), @provider_1
      assert_equal @relationship_1.partner_for_provider(@alternate_provider), nil
    end
    
    it "knows if one of the cooperating providers has been granted auto-approve permission by the other" do
      # :requesting_provider => @provider_1
      # :cooperating_provider => @provider_2

      @relationship_1.automatic_requester_approval = false
      @relationship_1.automatic_cooperator_approval = true
      @relationship_1.save!
      
      assert_equal false, @relationship_1.provider_can_auto_approve?(@provider_1)
      assert_equal true, @relationship_1.provider_can_auto_approve?(@provider_2)
    end
  end
end
