require 'test_helper'

class TripTicketTest < ActiveSupport::TestCase
  setup do
    @originator = FactoryGirl.create(:provider)
    @claimant = FactoryGirl.create(:provider)
    @third_party_provider = FactoryGirl.create(:provider)
    @ticket = FactoryGirl.create(:trip_ticket, :originator => @originator)
    @claim = FactoryGirl.create(
      :trip_claim,
      :trip_ticket => @ticket,
      :claimant => @claimant,
      :status => :pending)
    @ticket.trip_claims << @claim
    @result = TripResult.new(:outcome => "Completed")
    @another_result = TripResult.new(:outcome => "Completed")
  end

  it "must have an approved trip ticket" do
    assert !@result.valid?

    @result.trip_ticket = @ticket
    assert !@result.valid?

    @claim.approve! 
    assert @result.valid?
  end

  it "cannot be assigned to a ticket that already has a result" do
    @claim.approve!
    @result.trip_ticket = @ticket
    assert @result.save 
    
    @another_result.trip_ticket = @ticket
    assert !@another_result.save 
  end

  it "can only be edited by users belonging to the claiming or originating provider" do
    @claim.approve!
    @result.trip_ticket = @ticket
    @result.save!

    user = FactoryGirl.create(:user)

    user.provider = @claimant
    assert @result.can_be_edited_by?(user)

    user.provider = @originator
    assert @result.can_be_edited_by?(user)

    user.provider = @third_party_provider
    assert !@result.can_be_edited_by?(user)
  end

  it "should have a claimant method which returns the provider who submitted the result" do
    @claim.approve!
    @result.trip_ticket = @ticket
    @result.save!
    @result.must_respond_to :claimant
    @result.claimant.must_equal @claimant
  end

end
