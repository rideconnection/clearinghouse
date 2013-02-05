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
end
