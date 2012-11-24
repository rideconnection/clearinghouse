require 'spec_helper'

describe User do
  before :each do
    params = {
      :email => 'test@example.net',
      :name => 'Test User',
      :password => 'password 1',
      :password_confirmation => 'password 1',
    }
    @user = User.new params
    Role.new({:name => :guest}).save!
  end

  describe "password" do
    it "must be 8 - 20 characters in length and have at least one number and at least one non-alphanumeric character" do
      @user.password = @user.password_confirmation = nil
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = ""
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aaaaaa"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aaa123"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aa  aa"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "1---1"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aa 12"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aaaaaaaaaaaaaaaaaaa 1"
      @user.valid?.should be_false
      
      @user.password = @user.password_confirmation = "aaaa 1"
      @user.valid?.should be_true
      
      @user.password = @user.password_confirmation = "aa_123"
      @user.valid?.should be_true
      
      @user.password = @user.password_confirmation = "1----1"
      @user.valid?.should be_true
      
      @user.password = @user.password_confirmation = "aaa 12"
      @user.valid?.should be_true
      
      @user.password = @user.password_confirmation = "11111111111111      "
      @user.valid?.should be_true
      
      @user.password = @user.password_confirmation = "aaaaaaaaaaaaaaaaaa 1"
      @user.valid?.should be_true
    end
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
