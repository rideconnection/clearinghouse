require 'test_helper'
require 'trip_ticket_export'

class TripTicketExportTest < ActiveSupport::TestCase

  setup do
    @trip_ticket1 = FactoryGirl.create(:trip_ticket)
    @trip_ticket2 = FactoryGirl.create(:trip_ticket)
    @trip_ticket3 = FactoryGirl.create(:trip_ticket)
  end

  describe "#process" do
    it "stores exported trip tickets in the data attribute" do
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.wont_be_nil
    end

    it "exports all trips passed to it" do
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.must_match /^#{@trip_ticket1.id},/
      exporter.data.must_match /^#{@trip_ticket2.id},/
      exporter.data.must_match /^#{@trip_ticket3.id},/
    end

    it "limits exported trips" do
      exporter = TripTicketExport.new(2).tap {|x| x.process(TripTicket) }
      exporter.data.must_match /^#{@trip_ticket1.id},/
      exporter.data.must_match /^#{@trip_ticket2.id},/
      exporter.data.wont_match /^#{@trip_ticket3.id},/
    end

    it "exported data contains a header row" do
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.must_match /^id,[^\n]+$/
    end

    it "expands trips to include nested models" do
      FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket1, :status => :approved)
      @trip_ticket1.create_trip_result(:outcome => 'Completed', :driver_id => '_a_driver_')
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.must_match /,originator_name[^\w]/
      exporter.data.must_match /,originator_address_city[^\w]/
      exporter.data.must_match /,customer_address_city[^\w]/
      exporter.data.must_match /,pick_up_location_city[^\w]/
      exporter.data.must_match /,drop_off_location_city[^\w]/
      exporter.data.must_match /,trip_result_driver_id[^\w]/
      exporter.data.must_match /,_a_driver_[^\w]/
    end

    it "should not include trip ticket comments in the output" do
      FactoryGirl.create(:trip_ticket_comment, :trip_ticket => @trip_ticket1)
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.wont_match /,trip_ticket_comment/
    end

    it "should not include trip claims in the output" do
      FactoryGirl.create(:trip_claim, :trip_ticket => @trip_ticket1, :status => :approved)
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.data.wont_match /,trip_claim/
    end

    it "records the number of trips exported in the row_count attribute" do
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.row_count.must_equal 3
    end

    it "records the timestamp of the most recently updated trip in the last_exported_timestamp attribute" do
      exporter = TripTicketExport.new.tap {|x| x.process(TripTicket.all) }
      exporter.last_exported_timestamp.must_equal @trip_ticket3.reload.updated_at
    end
  end
end