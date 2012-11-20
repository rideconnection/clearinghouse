require 'spec_helper'

describe User do
  before :each do
    params = {
      :email => 'test@example.net',
      :name => 'Test User',
      :password => 'password',
      :password_confirmation => 'password',
    }
    @user = User.new params
    Role.new({:name => :guest}).save!
    
  end

  describe '#new' do
    it "is active by default" do
      @user.active.should be true
      @user.active_for_authentication?.should be true
    end
  end

  describe '#has_role?' do
    it "has an associated role" do
      @user.has_role?(:guest).should be false
      @user.roles << Role.find_by_name(:guest)
      @user.has_role?(:guest).should be true
    end
  end
end
