require 'test_helper'

class TripTicketTest < ActiveSupport::TestCase
  setup do
    @ticket = FactoryGirl.create(:trip_ticket)
    @claim = FactoryGirl.create(
      :trip_claim,
      :trip_ticket => @ticket,
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
end
