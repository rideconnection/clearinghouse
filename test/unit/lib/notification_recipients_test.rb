require 'test_helper'

class NotificationRecipientsTest < ActiveSupport::TestCase
  include NotificationRecipients

  setup do
    @provider_a = FactoryGirl.create(:provider)
    @provider_b = FactoryGirl.create(:provider)
    @provider_c = FactoryGirl.create(:provider)
    @user_a1 = FactoryGirl.create(:user, provider: @provider_a, email: 'user_a1@email.com', notification_preferences: ['some_mailer_method_name'])
    @user_a2 = FactoryGirl.create(:user, provider: @provider_a, email: 'user_a2@email.com', notification_preferences: ['x', 'some_mailer_method_name'])
    @user_b1 = FactoryGirl.create(:user, provider: @provider_b, email: 'user_b1@email.com', notification_preferences: ['some_mailer_method_name', 'y'])
    @user_c1 = FactoryGirl.create(:user, provider: @provider_c, email: 'user_c1@email.com', notification_preferences: ['x', 'some_mailer_method_name', 'y'])
    @notifier_options = { method: :some_mailer_method_name }
  end

  describe "#provider_users" do
    it "should return user emails for a specified provider" do
      emails = provider_users(@provider_a, @notifier_options)
      emails.must_include @user_a1.email
      emails.must_include @user_a2.email
      emails.wont_include @user_b1.email
      emails.wont_include @user_c1.email
    end
    it "should return user emails for an array of providers" do
      emails = provider_users([@provider_a, @provider_b], @notifier_options)
      emails.must_include @user_a1.email
      emails.must_include @user_a2.email
      emails.must_include @user_b1.email
      emails.wont_include @user_c1.email
    end
    it "should only return emails of users who enabled the specified notification type" do
      @user_a2.update_attributes(notification_preferences: ['this','that'])
      emails = provider_users(@provider_a, @notifier_options)
      emails.must_include @user_a1.email
      emails.wont_include @user_a2.email
    end
  end

  describe "#partner_users" do
    setup do
      @provider_relationship_b = FactoryGirl.create(:provider_relationship, requesting_provider: @provider_a, cooperating_provider: @provider_b)
      @provider_relationship_c = FactoryGirl.create(:provider_relationship, requesting_provider: @provider_a, cooperating_provider: @provider_c)
      @trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider_a)
    end

    it "should return user emails for all approved partners of a trip ticket's originator" do
      emails = partner_users(@trip_ticket, @notifier_options)
      emails.must_include @user_b1.email
      emails.must_include @user_c1.email
    end

    it "should not return user emails for unapproved partners" do
      @provider_relationship_c.update_attributes(approved_at: nil)
      emails = partner_users(@trip_ticket, @notifier_options)
      emails.wont_include @user_c1.email
    end

    it "should not return originator's users" do
      emails = partner_users(@trip_ticket, @notifier_options)
      emails.wont_include @user_a1.email
      emails.wont_include @user_a2.email
    end

    it "should not return user emails for any providers in a trip ticket's blacklist" do
      @trip_ticket.update_attributes(provider_black_list: [@provider_c.id])
      emails = partner_users(@trip_ticket, @notifier_options)
      emails.must_include @user_b1.email
      emails.wont_include @user_c1.email
    end

    it "should only return user emails for providers in a trip ticket's whitelist" do
      @trip_ticket.update_attributes(provider_white_list: [@provider_b.id])
      emails = partner_users(@trip_ticket, @notifier_options)
      emails.must_include @user_b1.email
      emails.wont_include @user_c1.email
    end
  end

  describe "#claimant_users" do
    setup do
      @trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider_a)
      @trip_claim_b = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket, claimant: @provider_b, status: :pending)
      @trip_claim_c = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket, claimant: @provider_c, status: :approved)
    end

    it "should return user emails for all providers who have active claims on a trip ticket" do
      emails = claimant_users(@trip_ticket, @notifier_options)
      emails.must_include @user_b1.email
      emails.must_include @user_c1.email
    end

    it "should not return user emails for providers who have inactive claims on a trip ticket" do
      @trip_claim_b.update_attribute(:status, :declined)
      emails = claimant_users(@trip_ticket, @notifier_options)
      emails.wont_include @user_b1.email
      emails.must_include @user_c1.email
    end

    it "should not return user emails of trip ticket originator" do
      emails = claimant_users(@trip_ticket, @notifier_options)
      emails.wont_include @user_a1.email
      emails.wont_include @user_a2.email
    end
  end

  describe "#originator_and_claimant_users" do
    setup do
      @trip_ticket = FactoryGirl.create(:trip_ticket, originator: @provider_a)
      @trip_claim_b = FactoryGirl.create(:trip_claim, trip_ticket: @trip_ticket, claimant: @provider_b, status: :pending)
    end

    it "should return user emails for originator and active claimants of a trip ticket" do
      emails = originator_and_claimant_users(@trip_ticket, @notifier_options)
      emails.must_include @user_a1.email
      emails.must_include @user_a2.email
      emails.must_include @user_b1.email
    end
  end
end
