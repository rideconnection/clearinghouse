require 'test_helper'
require 'trip_ticket_import'

class TripTicketImportTest < ActiveSupport::TestCase

  setup do
    @csv_header = 'id,origin_provider_id,origin_customer_id,origin_trip_id,customer_first_name,customer_last_name,customer_middle_name,customer_dob,customer_primary_phone,customer_emergency_phone,customer_primary_language,customer_ethnicity,customer_race,customer_information_withheld,customer_notes,customer_boarding_time,customer_deboarding_time,customer_seats_required,customer_impairment_description,customer_service_level,customer_mobility_factors,customer_service_animals,customer_eligibility_factors,num_attendants,num_guests,requested_pickup_time,earliest_pick_up_time,appointment_time,requested_drop_off_time,allowed_time_variance,trip_purpose_description,trip_funders,trip_notes,scheduling_priority,customer_address_address_1,customer_address_address_2,customer_address_city,customer_address_position,customer_address_state,customer_address_zip,pick_up_location_address_1,pick_up_location_address_2,pick_up_location_city,pick_up_location_position,pick_up_location_state,pick_up_location_zip,drop_off_location_address_1,drop_off_location_address_2,drop_off_location_city,drop_off_location_position,drop_off_location_state,drop_off_location_zip'

    @csv_new_attrs = ',,customer123,trip123,Joe,Testington,,2/5/16,(123) 456-7890,,,,,FALSE,,0,0,1,,,,,,0,0,2000-01-01T00:00:00Z,,2013-08-31T17:00:00-07:00,2000-01-01T00:00:00Z,-1,,,,pickup,123 Main St Apt B,,Chelmsford,,MA,01110,5 Barker St,,Boston,,MA,02134,123 Main St Apt A,,Andover,,MA,01810'
    @csv_new = @csv_header + "\n" + @csv_new_attrs

    @csv_invalid_attrs = ',,,,,,2/5/16,(123) 456-7890,,,,,FALSE,,0,0,1,,,,,,0,0,2000-01-01T00:00:00Z,,2013-08-31T17:00:00-07:00,2000-01-01T00:00:00Z,-1,,,,pickup,123 Main St Apt B,,Chelmsford,,MA,01110,5 Barker St,,Boston,,MA,02134,123 Main St Apt A,,Andover,,MA,01810'
    @csv_invalid = @csv_header + "\n" + @csv_invalid_attrs

    @existing_trip = FactoryGirl.create(:trip_ticket)
  end

  describe "#process" do
    describe "with invalid originator" do
      let(:importer) { TripTicketImport.new(nil) }

      it "should require an originating provider for creating trip tickets" do
        ->{ importer.process(@csv_new) }.must_raise(ArgumentError)
      end
    end

    describe "with valid originator" do
      let(:importer) { TripTicketImport.new(@existing_trip.originator) }

      it "should create new trip tickets for imported rows that have no ID" do
        assert_difference 'TripTicket.count', +1 do
          importer.process(@csv_new)
        end
      end

      it "should store the count of imported rows in the row_count attribute" do
        importer.process(@csv_new)
        importer.row_count.must_equal 1
      end

      it "should reject rows that would create an invalid trip ticket" do
        assert_no_difference 'TripTicket.count' do
          importer.process(@csv_invalid)
        end
      end

      it "should store the number of rows with errors in the errors attribute" do
        importer.process(@csv_invalid)
        importer.errors.length.must_equal 1
      end

      it "should require a header row in the imported file" do
        importer.process(@csv_new_attrs)
        importer.row_count.must_equal 0
        importer.errors.first.must_equal "No data rows found, import cancelled"
      end

      it "should update existing trip tickets with matching ID" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        @existing_trip.origin_customer_id.must_equal 'customer123'
      end

      it "should reject rows with IDs that do not match existing trips" do
        csv_update = @csv_header + "\n" + "1234567" + @csv_new_attrs
        old_attrs = @existing_trip.attributes
        assert_no_difference 'TripTicket.count' do
          importer.process(csv_update)
        end
        importer.errors.length.must_equal 1
        @existing_trip.reload
        @existing_trip.attributes.must_equal old_attrs
      end

      it "should ignore attempts to import a specific trip origin_provider_id" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        csv_update.gsub(/,,customer123/, ',999999,customer123')
        old_attr = @existing_trip.origin_provider_id
        importer.process(csv_update)
        importer.errors.length.must_equal 0
        @existing_trip.reload
        @existing_trip.origin_provider_id.must_equal old_attr
      end

      it "should reject rows where trip being updated was originated by a different provider" do
        different_importer = TripTicketImport.new(FactoryGirl.create(:provider))
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        old_attrs = @existing_trip.attributes
        assert_no_difference 'TripTicket.count' do
          different_importer.process(csv_update)
        end
        different_importer.errors.length.must_equal 1
        @existing_trip.reload
        @existing_trip.attributes.must_equal old_attrs
      end

      it "should update existing trip tickets with matching origin_trip_id and appointment_time" do
        @existing_trip2 = FactoryGirl.create(:trip_ticket, originator: @existing_trip.originator, origin_trip_id: 'trip123', appointment_time: Time.parse("2013-08-31T17:00:00-07:00"))
        assert_no_difference 'TripTicket.count' do
          importer.process(@csv_new)
        end
        @existing_trip2.reload
        @existing_trip2.origin_customer_id.must_equal 'customer123'
      end

      it "should cancel the entire import if any row has an error" do
        csv_good_and_bad = @csv_new + "\n" + @csv_invalid_attrs
        assert_no_difference 'TripTicket.count' do
          importer.process(csv_good_and_bad)
        end
        importer.errors.length.must_equal 1
      end

      it "should create new records for nested models without an ID" do
        # customer_address, pick_up_location, drop_off_location
        assert_difference 'Location.count', 3 do
          importer.process(@csv_new)
        end
      end

      it "should update existing records for nested models with an ID" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        csv_location_update = "id,customer_address_id,customer_address_address_1\n#{@existing_trip.id},#{@existing_trip.customer_address_id},4321 Backwards St"
        assert_no_difference 'Location.count' do
          importer.process(csv_location_update)
        end
        @existing_trip.reload
        @existing_trip.customer_address.address_1.must_equal '4321 Backwards St'
      end

      it "should import array fields" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        csv_array_update = "id,customer_service_animals\n#{@existing_trip.id}," + '"{""rhino"",""donkey"",""elephant""}"'
        importer.process(csv_array_update)
        @existing_trip.reload
        @existing_trip.customer_service_animals.must_be_kind_of Array
        @existing_trip.customer_service_animals.must_include 'rhino'
        @existing_trip.customer_service_animals.must_include 'elephant'
        @existing_trip.customer_service_animals.must_include 'donkey'
      end

      it "should import hstore fields" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        csv_array_update = "id,customer_identifiers\n#{@existing_trip.id}," + '"""eye_color""=>""brown"",""eye_count""=>""2"""'
        importer.process(csv_array_update)
        @existing_trip.reload
        @existing_trip.customer_identifiers.must_be_kind_of Hash
        @existing_trip.customer_identifiers["eye_color"].must_equal "brown"
        @existing_trip.customer_identifiers["eye_count"].must_equal "2"
      end

      it "should normalize location lat and lon to WKT" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        csv_location_update = "id,customer_address_id,customer_address_lat,customer_address_lon\n#{@existing_trip.id},#{@existing_trip.customer_address_id},45,-27"
        importer.process(csv_location_update)
        @existing_trip.reload
        @existing_trip.customer_address.position.to_s.must_equal 'POINT (-27.0 45.0)'
      end

      it "should normalize location position to WKT" do
        csv_update = @csv_header + "\n" + "#{@existing_trip.id}" + @csv_new_attrs
        importer.process(csv_update)
        @existing_trip.reload
        csv_location_update = "id,customer_address_id,customer_address_position\n#{@existing_trip.id},#{@existing_trip.customer_address_id},\"-27, 45\""
        importer.process(csv_location_update)
        @existing_trip.reload
        @existing_trip.customer_address.position.to_s.must_equal 'POINT (-27.0 45.0)'
      end
    end
  end
end