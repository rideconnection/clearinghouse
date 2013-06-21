module Clearinghouse
  class API_v1 < Grape::API
    helpers APIHelpers
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do

      namespace :trip_tickets do
        desc "Get list of trips accessible to the requesting provider"
        #params do
          # TODO add all available trip filters as optional params with descriptions so the API is self-documenting
        #end
        get do
          present trip_tickets_filter(TripTicket.accessible_by(current_ability)), with: Clearinghouse::Entities::V1::TripTicket
        end

        desc "Get detailed list of trips related to requesting provider including all associated objects"
        params do
          optional :updated_since, type: String, desc: "Shortcut for trip_ticket_filters[updated_at][start]="
        end
        get 'sync' do
          params.merge!({ trip_ticket_filters: { updated_at: { start: params[:updated_since] }}}) if params[:updated_since]
          # using accessible_by and trying to chain originated_or_claimed_by does not work because accessible_by only allows originated trips through
          #trips = trip_tickets_filter(TripTicket.accessible_by(current_ability).originated_or_claimed_by(current_provider))
          trips = trip_tickets_filter(TripTicket.originated_or_claimed_by(current_provider))
          present trips, with: Clearinghouse::Entities::V1::TripTicketDetailed, current_provider: current_provider
        end

        # TODO add all available parameters to create/update actions so API is self-documenting
        #params do
          #group :trip_ticket do
            #requires :customer_dob, :customer_first_name, :customer_last_name,
            #  :customer_primary_phone, :customer_seats_required, :origin_customer_id,
            #  :requested_drop_off_time, :requested_pickup_time
          #end
        #end
        desc "Create a trip ticket"
        post do
          trip_ticket = TripTicket.new(params[:trip_ticket])
          trip_ticket.origin_provider_id ||= current_provider.id
          error! "Access Denied", 401 unless current_ability.can?(:create, trip_ticket)
          if trip_ticket.save
            present trip_ticket, with: Clearinghouse::Entities::V1::TripTicketDetailed
          else
            error!({message: "Could not create trip ticket", errors: trip_ticket.errors}, 422)
          end
        end

        params do
          requires :id, :type => Integer, :desc => 'Trip ticket ID.'
        end
        scope :requires_id do
          desc "Get a specific trip ticket"
          get ':id' do
            # to allow CanCan abilities to fully control access to tickets, do not limit scope to provider's own trips
            trip_ticket = TripTicket.find(params[:id])
            error! "Access Denied", 401 unless current_ability.can?(:show, trip_ticket)
            present trip_ticket, with: Clearinghouse::Entities::V1::TripTicketDetailed
          end

          desc "Update a trip ticket"
          put ':id' do
            trip_ticket = TripTicket.find(params[:id])
            error! "Access Denied", 401 unless current_ability.can?(:update, trip_ticket)
            if trip_ticket.update_attributes(params[:trip_ticket])
              present trip_ticket, with: Clearinghouse::Entities::V1::TripTicketDetailed
            else
              error!({message: "Could not update trip ticket", errors: trip_ticket.errors}, 422)
            end
          end

          desc "Rescind a trip ticket"
          put ':id/rescind' do
            trip_ticket = TripTicket.find(params[:id])
            error! "Access Denied", 401 unless current_ability.can?(:rescind, trip_ticket)
            if trip_ticket.rescind!
              present trip_ticket, with: Clearinghouse::Entities::V1::TripTicketDetailed
            else
              error!({message: "Could not rescind trip ticket", errors: trip_ticket.errors}, 422)
            end
          end
        end # scope :requires_id
      end # namespace :trip_tickets

    end
  end
end
