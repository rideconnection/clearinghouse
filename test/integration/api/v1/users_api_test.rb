require 'test_helper'
require 'api_param_factory'

describe "Clearinghouse::API_v1 users endpoints" do
  before do
    @provider = FactoryGirl.create(:provider)
    @user1 = FactoryGirl.create(:user, name: "Phil", active: true, provider: @provider)
    @user2 = FactoryGirl.create(:user, name: "Bill", provider: @provider)
    @user3 = FactoryGirl.create(:user, name: "Mark", provider: FactoryGirl.create(:provider))
  end
  
  describe "GET /api/v1/users" do
    include_examples "requires authenticatable params"

    it "should return all provider users as JSON" do
      get "/api/v1/users", api_params(@provider)
      response.status.must_equal 200
      response.body.must_include %Q{"name":"#{@user1.name}"}
      response.body.must_include %Q{"name":"#{@user2.name}"}
      response.body.wont_include %Q{"name":"#{@user3.name}"}
    end
  end

  describe "GET /api/v1/users/1" do
    include_examples "requires authenticatable params"

    it "should return the specified provider user as JSON" do
      get "/api/v1/users/#{@user1.id}", api_params(@provider, id: @user1.id)
      response.status.must_equal 200
      response.body.must_include %Q{"name":"#{@user1.name}"}
    end

    it "should not allow me to access a user belonging to another provider" do
      get "/api/v1/users/#{@user3.id}", api_params(@provider, id: @user3.id)
      response.status.must_equal 404
      response.body.wont_include %Q{"name":"#{@user3.name}"}
    end
  end

  describe "PUT /api/v1/users/1" do
    include_examples "requires authenticatable params"

    it "should update the specified provider user and return the user as JSON" do
      put "/api/v1/users/#{@user1.id}", api_params(@provider, id: @user1.id, user: {name: "Mary"})
      response.status.must_equal 200
      response.body.must_include %Q{"name":"Mary"}
      @user1.reload
      @user1.name.must_equal "Mary"
    end

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/#{@user3.id}", api_params(@provider, id: @user3.id, user: {name: "Mary"})
      response.status.must_equal 404
      response.body.wont_include %Q{"name":"Mary"}
    end
  end

  describe "PUT /api/v1/users/1/activate" do
    before do
      @user1.update_attribute(:active, false)
    end
    
    include_examples "requires authenticatable params"

    it "should activate the specified provider user and return the user as JSON" do
      put "/api/v1/users/#{@user1.id}/activate", api_params(@provider, id: @user1.id)
      response.status.must_equal 200
      response.body.must_include %Q{"active":true}
      @user1.reload
      @user1.active.must_equal true
    end

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/#{@user3.id}/activate", api_params(@provider, id: @user3.id)
      response.status.must_equal 404
      response.body.wont_include %Q{"active":true"}
    end
  end

  describe "PUT /api/v1/users/1/deactivate" do
    before do
      @user1.update_attribute(:active, true)
    end
    
    include_examples "requires authenticatable params"

    it "should deactivate the specified provider user and return the user as JSON" do
      put "/api/v1/users/#{@user1.id}/deactivate", api_params(@provider, id: @user1.id)
      response.status.must_equal 200
      response.body.must_include %Q{"active":false}
      @user1.reload
      @user1.active.must_equal false
    end

    it "should not allow me to access a user belonging to another provider" do
      put "/api/v1/users/#{@user3.id}/deactivate", api_params(@provider, id: @user3.id)
      response.status.must_equal 404
      response.body.wont_include %Q{"active":false"}
    end
  end
end
