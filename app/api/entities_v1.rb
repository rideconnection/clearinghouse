module Clearinghouse
  module Entities
    module V1
      class User < Grape::Entity
        expose :id, :active, :email, :name, :phone, :roles, :title
      end

      class Location < Grape::Entity
        expose :address_1, :address_2, :city, :position, :state, :zip
      end

      class Provider < Grape::Entity
        expose :name, :primary_contact_id
        expose :primary_contact, :using => Clearinghouse::Entities::V1::User
        expose :address, :as => :foo, :using => Location
      end

      class TripTicket < Grape::Entity
        # TODO expose originator object? probably not, they know who they are
        # TODO expose trip_claims (has_many), trip_ticket_comments (has_many), and trip_result (has_one)?
        # TODO assuming anything in attr_accessible is fair game for the API to expose, but double-check
        # TODO should collection version of TripTicket return summary details for listing to keep the data size lower?
        #      seems silly to return the full detail in the collection, then have a SHOW action that gives the same detail
        # TODO should the API be able to look up a ticket by the origin_customer_id or origin_trip_id? seems like adapter will need this

        expose :id,
          :origin_provider_id, :origin_customer_id, :origin_trip_id,
          :claimant_provider_id, :claimant_trip_id,
          :pick_up_location_id, :drop_off_location_id, :customer_address_id,
          :customer_first_name, :customer_last_name, :customer_middle_name, :customer_dob,
          :customer_primary_phone, :customer_emergency_phone,
          :customer_primary_language, :customer_ethnicity, :customer_race,
          :customer_information_withheld, :customer_identifiers, :customer_notes,
          :customer_boarding_time, :customer_deboarding_time, :customer_seats_required,
          :customer_impairment_description, :customer_mobility_impairments, :customer_assistive_devices,
          :customer_service_animals, :customer_eligibility_factors,
          :num_attendants, :num_guests, :guest_or_attendant_service_animals, :guest_or_attendant_assistive_devices,
          :requested_pickup_time, :earliest_pick_up_time, :appointment_time, :requested_drop_off_time,
          :allowed_time_variance, :trip_purpose_description, :trip_funders, :trip_notes, :scheduling_priority

        expose :pick_up_location, :using => Clearinghouse::Entities::V1::Location
        expose :drop_off_location, :using => Clearinghouse::Entities::V1::Location
        expose :customer_address, :using => Clearinghouse::Entities::V1::Location
        expose :claimant, :using => Clearinghouse::Entities::V1::Provider
      end
    end
  end
end
