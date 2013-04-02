module Clearinghouse
  class API_v1 < Grape::API
    helpers APIHelpers
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do

      namespace :trip_tickets do
        params do
          requires :trip_ticket_id, :type => Integer, :desc => 'Trip ticket ID.'
        end
        namespace ':trip_ticket_id' do
          namespace :trip_result do

            desc "Get trip result for the specified trip"
            get do
              trip_result = TripTicket.find(params[:trip_ticket_id]).trip_result
              error! "Not Found", 404 if trip_result.nil?
              error! "Access Denied", 401 unless current_ability.can?(:show, trip_result)
              present trip_result, with: Clearinghouse::Entities::V1::TripResult
            end

            desc "Create trip result"
            post do
              trip_ticket = TripTicket.find(params[:trip_ticket_id])
              trip_result = trip_ticket.build_trip_result(params[:trip_result])
              error! "Access Denied", 401 unless current_ability.can?(:create, trip_result)
              if trip_result.save
                present trip_result, with: Clearinghouse::Entities::V1::TripResult
              else
                error!({message: "Could not create trip result", errors: trip_result.errors}, 422)
              end
            end

            desc "Update trip result"
            put ':id' do
              trip_result = TripTicket.find(params[:trip_ticket_id]).trip_result
              error! "Not Found", 404 if trip_result.nil?
              error! "Access Denied", 401 unless current_ability.can?(:update, trip_result)
              if trip_result.update_attributes(params[:trip_result])
                present trip_result, with: Clearinghouse::Entities::V1::TripResult
              else
                error!({message: "Could not update trip result", errors: trip_result.errors}, 422)
              end
            end

          end # namespace :trip_result
        end # scope '/:trip_ticket_id'
      end # namespace :trip_tickets

    end
  end
end
