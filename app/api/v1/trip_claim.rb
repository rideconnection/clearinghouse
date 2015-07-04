module Clearinghouse
  class API_v1 < Grape::API
    helpers API_Authentication
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do
      params do
        use :authentication_params
      end

      namespace :trip_tickets do
        params do
          # for consistency with Rails conventions for nested resource routes
          requires :trip_ticket_id, :type => Integer, :desc => 'Trip ticket ID.'
        end
        namespace ':trip_ticket_id' do
          namespace :trip_claims do
            desc "Get list of claims for the specified trip"
            get do
              trip_ticket = TripTicket.find(params[:trip_ticket_id])
              present trip_ticket.trip_claims.accessible_by(current_ability), with: Clearinghouse::Entities::V1::TripClaim
            end

            desc "Create a trip claim"
            post do
              trip_ticket = TripTicket.find(params[:trip_ticket_id])
              trip_claim = trip_ticket.trip_claims.build(params[:trip_claim])
              trip_claim.claimant_provider_id ||= current_provider.id
              error! "Access Denied", 401 unless current_ability.can?(:create, trip_claim)
              if trip_claim.save
                present trip_claim, with: Clearinghouse::Entities::V1::TripClaimDetailed
              else
                error!({message: "Could not create trip claim", errors: trip_claim.errors}, 422)
              end
            end

            params do
              requires :id, :type => Integer, :desc => 'Trip claim ID.'
            end
            scope :requires_id do
              desc "Get a specific trip claim"
              get ':id' do
                trip_claim = TripTicket.find(params[:trip_ticket_id]).trip_claims.find(params[:id])
                error! "Access Denied", 401 unless current_ability.can?(:show, trip_claim)
                present trip_claim, with: Clearinghouse::Entities::V1::TripClaimDetailed
              end

              desc "Update a trip claim"
              put ':id' do
                trip_claim = TripTicket.find(params[:trip_ticket_id]).trip_claims.find(params[:id])
                error! "Access Denied", 401 unless current_ability.can?(:update, trip_claim)
                if trip_claim.update_attributes(params[:trip_claim])
                  present trip_claim, with: Clearinghouse::Entities::V1::TripClaimDetailed
                else
                  error!({message: "Could not update trip claim", errors: trip_claim.errors}, 422)
                end
              end

              [:rescind, :decline, :approve].each do |action|
                desc "#{action.to_s.capitalize} a trip claim"
                put ":id/#{action}" do
                  trip_claim = TripTicket.find(params[:trip_ticket_id]).trip_claims.find(params[:id])
                  error! "Access Denied", 401 unless current_ability.can?(action, trip_claim)
                  if trip_claim.send("#{action}!")
                    present trip_claim, with: Clearinghouse::Entities::V1::TripClaimDetailed
                  else
                    error!({message: "Could not #{action} trip claim", errors: trip_claim.errors}, 422)
                  end
                end
              end
            end # scope :requires_id
          end # namespace :trip_claims
        end # scope '/:trip_ticket_id'
      end # namespace :trip_tickets

    end
  end
end
