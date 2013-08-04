module Clearinghouse
  module Entities
    module V1
      class Role < Grape::Entity
        expose :name
      end

      class User < Grape::Entity
        expose :id, :active, :email, :name, :phone, :title
        expose :role, :using => Role
      end

      class Location < Grape::Entity
        expose :id, :address_1, :address_2, :city, :position, :state, :zip, :created_at, :updated_at
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
      end

      class TripResult < Grape::Entity
        expose :id, :actual_drop_off_time, :actual_pick_up_time, :base_fare,
          :billable_mileage, :driver_id, :extra_securement_count, :fare, :fare_type,
          :miles_traveled, :odometer_end, :odometer_start, :outcome, :rate,
          :rate_type, :trip_claim_id, :trip_ticket_id, :vehicle_id, :vehicle_type,
          :created_at, :updated_at
      end

      class TripClaim < Grape::Entity
        expose :id,
          :claimant_provider_id, :claimant_customer_id, :claimant_service_id, :claimant_trip_id,
          :trip_ticket_id, :status, :proposed_pickup_time, :proposed_fare, :notes, :created_at, :updated_at
        # indicates if current provider is the creator of the claim
        expose :is_claimant, unless: { current_provider: nil }  do |claim, options|
          claim.claimant_provider_id == options[:current_provider].id
        end
      end

      class TripClaimDetailed < TripClaim
        expose :claimant, :using => Provider
      end

      class TripTicket < Grape::Entity
        format_with(:precise_timestamp) {|dt| dt.strftime("%Y-%m-%d %H:%M:%S.%6N") }

        expose :id, :rescinded,
          :origin_provider_id, :origin_customer_id, :origin_trip_id,
          :pick_up_location_id, :drop_off_location_id, :customer_address_id,
          :customer_first_name, :customer_last_name, :customer_middle_name,
          :customer_dob, :customer_primary_phone, :customer_emergency_phone,
          :customer_primary_language, :customer_ethnicity, :customer_race,
          :customer_information_withheld, :customer_identifiers,
          :customer_notes, :customer_boarding_time, :customer_deboarding_time,
          :customer_seats_required, :customer_impairment_description,
          :customer_mobility_impairments, :customer_assistive_devices,
          :customer_service_animals, :customer_eligibility_factors,
          :num_attendants, :num_guests, :guest_or_attendant_service_animals,
          :guest_or_attendant_assistive_devices, :requested_pickup_time,
          :earliest_pick_up_time, :appointment_time, :requested_drop_off_time,
          :allowed_time_variance, :trip_purpose_description, :trip_funders,
          :trip_notes, :scheduling_priority

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
