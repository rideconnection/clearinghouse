require 'test_helper'

class TripTicketCommentTest < ActiveSupport::TestCase
  it "has an associated trip ticket" do
    tt = FactoryGirl.create(:trip_ticket)
    c = FactoryGirl.create(:trip_ticket_comment, :trip_ticket => tt)
    assert_equal tt, c.trip_ticket
  end
  
  it "has an associated user" do
    u = FactoryGirl.create(:user)
    c = FactoryGirl.create(:trip_ticket_comment, :user => u)
    assert_equal u, c.user
  end
  
  describe "validations" do
    it "requires :body" do
      tt = TripTicketComment.new
      assert_equal false, tt.valid?
      assert_includes tt.errors.keys, :body
    end

    it "requires :trip_ticket_id" do
      tt = TripTicketComment.new
      assert_equal false, tt.valid?
      assert_includes tt.errors.keys, :trip_ticket_id
    end

    it "requires :user_id" do
      tt = TripTicketComment.new
      assert_equal false, tt.valid?
      assert_includes tt.errors.keys, :user_id
    end
  end

  describe "notifications" do
    setup do
      @acts_as_notifier_disbled = ActsAsNotifier::Config.disabled
      @acts_as_notifier_use_delayed_job = ActsAsNotifier::Config.use_delayed_job
      ActsAsNotifier::Config.disabled = false
      ActsAsNotifier::Config.use_delayed_job = false
      @recipients = 'aaa@example.com, bbb@example.com'
      TripTicketComment.all_instances.stub(:originator_and_claimant_users, @recipients)
    end

    teardown do
      ActsAsNotifier::Config.disabled = @acts_as_notifier_disbled
      ActsAsNotifier::Config.use_delayed_job = @acts_as_notifier_use_delayed_job
      TripTicketComment.all_instances.unstub(:originator_and_claimant_users)
    end

    it "should notify trip ticket originator and claimant users when a trip ticket comment is added" do
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        FactoryGirl.create(:trip_ticket_comment)
      end
      validate_last_delivery(@recipients, 'Ride Connection Clearinghouse: trip ticket comment added')
    end
  end
end
