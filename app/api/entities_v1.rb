module Clearinghouse
  module Entities
    module V1
      class Role < Grape::Entity
        expose :id, :name
      end

      class User < Grape::Entity
        expose :id, :active, :email, :name, :phone, :title
        expose :role, :using => Role
      end

      class Location < Grape::Entity
        expose :id, :address_1, :address_2, :city, :position, :state, :zip,
               :phone_number, :common_name, :jurisdiction,
               :created_at, :updated_at
      end

      class Provider < Grape::Entity
        expose :id, :name, :primary_contact_email
        expose :address, :using => Location
      end

      class TripTicketComment < Grape::Entity
        expose :id, :body, :trip_ticket_id, :created_at, :updated_at
        expose :user_name do |comment, options|
          comment.user.name
        end
        expose :origin_trip_id do |comment, options|
          comment.trip_ticket.try(:origin_trip_id)
        end
      end

      class TripResult < Grape::Entity
        expose :id, :actual_drop_off_time, :actual_pick_up_time, :base_fare,
          :billable_mileage, :driver_id, :extra_securement_count, :fare, :fare_type,
          :miles_traveled, :odometer_end, :odometer_start, :outcome, :rate,
          :rate_type, :trip_claim_id, :trip_ticket_id, :vehicle_id, :vehicle_type,
          :notes, :created_at, :updated_at
        expose :origin_trip_id do |result, options|
          result.trip_ticket.try(:origin_trip_id)
        end
      end

      class TripClaim < Grape::Entity
        expose :id,
          :claimant_provider_id, :claimant_name, :claimant_customer_id, :claimant_service_id, :claimant_trip_id,
          :trip_ticket_id, :status, :proposed_pickup_time, :proposed_fare, :notes, :created_at, :updated_at
        # indicates if current provider is the creator of the claim
        expose :is_claimant, unless: { current_provider: nil }  do |claim, options|
          claim.claimant_provider_id == options[:current_provider].id
        end
        expose :origin_trip_id do |claim, options|
          claim.trip_ticket.try(:origin_trip_id)
        end
        expose :claimant_name do |claim, options|
          claim.claimant.try(:name)
        end
      end

      class TripClaimDetailed < TripClaim
        expose :claimant, :using => Provider
      end

      class TripTicket < Grape::Entity
        format_with(:precise_timestamp) {|dt| dt.strftime("%Y-%m-%d %H:%M:%S.%6N") }

        # note: status is a virtual API field and cannot be set on actual trips

        expose :id, :status, :rescinded,
          :origin_provider_id, :origin_customer_id, :origin_trip_id,
          :pick_up_location_id, :drop_off_location_id, :customer_address_id,
          :customer_first_name, :customer_last_name, :customer_middle_name,
          :customer_dob, :customer_primary_phone, :customer_emergency_phone,
          :customer_primary_language, :customer_ethnicity, :customer_race,
          :customer_information_withheld, :customer_identifiers,
          :customer_notes, :customer_boarding_time, :customer_deboarding_time,
          :customer_seats_required, :customer_impairment_description,
          :customer_service_level, :customer_mobility_factors,
          :customer_service_animals, :customer_eligibility_factors,
          :num_attendants, :num_guests, :requested_pickup_time,
          :earliest_pick_up_time, :appointment_time, :requested_drop_off_time,
          :trip_purpose_description, :trip_funders,
          :trip_notes, :scheduling_priority,
          :customer_gender, :estimated_distance, :additional_data,
          :time_window_before, :time_window_after

        expose :created_at, :format_with => :precise_timestamp
        expose :updated_at, :format_with => :precise_timestamp

        # indicates if current provider is the originator of the trip
        expose :is_originator, unless: { current_provider: nil } do |trip, options|
          trip.origin_provider_id == options[:current_provider].id
        end
      end

      class TripTicketDetailed < TripTicket
        expose :originator, :using => Provider
        expose :claimant, :using => Provider
        expose :customer_address, :using => Location
        expose :pick_up_location,  :using => Location
        expose :drop_off_location, :using => Location
        expose :trip_result, :using => TripResult
        expose :trip_claims, :using => TripClaim
        expose :trip_ticket_comments, :using => TripTicketComment
      end

    end
  end
end
