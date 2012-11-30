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
    describe "complexity requirements" do
      # must be 6 - 20 characters in length and have at least one number and at least one non-alphanumeric character
      it { should_not accept_values_for(:password, nil, "") }    
      it { should_not accept_values_for(:password, "aaaaaa") }
      it { should_not accept_values_for(:password, "aaa123") }
      it { should_not accept_values_for(:password, "aa  aa") }
      it { should_not accept_values_for(:password, "1---1") }
      it { should_not accept_values_for(:password, "aa 12") }
      it { should_not accept_values_for(:password, "aaaaaaaaaaaaaaaaaaa 1") }
    
      it { should accept_values_for(:password, "aaaa 1") }
      it { should accept_values_for(:password, "aa_123") }
      it { should accept_values_for(:password, "1----1") }
      it { should accept_values_for(:password, "aaa 12") }
      it { should accept_values_for(:password, "11111111111111      ") }
      it { should accept_values_for(:password, "aaaaaaaaaaaaaaaaaa 1") }
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
