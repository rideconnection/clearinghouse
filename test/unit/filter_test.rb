require 'test_helper'

class TripClaimTest < ActiveSupport::TestCase
  it "should require user_id attribute" do
    filter = FactoryGirl.build(:filter, :user => nil)
    filter.valid?.must_equal false
    filter.errors[:user_id].must_include "can't be blank"
  end

  it "should require name attribute" do
    filter = FactoryGirl.build(:filter, :name => nil)
    filter.valid?.must_equal false
    filter.errors[:name].must_include "can't be blank"
  end

  it "should require data attribute" do
    filter = FactoryGirl.build(:filter, :data => nil)
    filter.valid?.must_equal false
    filter.errors[:data].must_include "can't be blank"
  end

  it "should require a unique name per user" do
    filter1 = FactoryGirl.create(:filter)
    filter2 = FactoryGirl.build(:filter, :user => filter1.user, :name => filter1.name)
    filter2.valid?.must_equal false
    filter2.errors[:name].must_include "has already been taken"
  end

  it "should serialize the data attribute" do
    filter = FactoryGirl.create(:filter, :data => { 'test' => 'hash' })
    filter.reload
    filter.data['test'].must_equal 'hash'
  end
end
