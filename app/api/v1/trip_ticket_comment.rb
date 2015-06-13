module Clearinghouse
  class API_v1 < Grape::API
    # helpers APIHelpers
    # include API_Authentication
    version 'v1', :using => :path, :vendor => 'Clearinghouse' do

      namespace :trip_tickets do
        params do
          requires :trip_ticket_id, :type => Integer, :desc => 'Trip ticket ID.'
        end
        namespace ':trip_ticket_id' do
          namespace :trip_ticket_comments do
            desc "Get list of comments for the specified trip"
            get do
              trip_ticket = TripTicket.find(params[:trip_ticket_id])
              error! "Access Denied", 401 unless current_ability.can?(:read, trip_ticket)
              present trip_ticket.trip_ticket_comments.accessible_by(current_ability),
                      with: Clearinghouse::Entities::V1::TripTicketComment
            end

            desc "Create a trip comment"
            post do
              trip_ticket = TripTicket.find(params[:trip_ticket_id])
              trip_ticket_comment = trip_ticket.trip_ticket_comments.build(params[:trip_ticket_comment])

              # API can only create a comment on behalf of users belonging to the provider
              user = User.find(params[:trip_ticket_comment][:user_id])
              error! "Invalid User", 401 unless user.provider_id == current_provider.id

              # TODO should we assume API can create a comment for any user or should we check user's ability to create comments?
              error! "Access Denied", 401 unless ::Ability.new(user).can?(:create, trip_ticket_comment)
              error! "Access Denied", 401 unless current_ability.can?(:create, trip_ticket_comment)
              if trip_ticket_comment.save
                present trip_ticket_comment, with: Clearinghouse::Entities::V1::TripTicketComment
              else
                error!({message: "Could not create trip comment", errors: trip_ticket_comment.errors}, 422)
              end
            end

            params do
              requires :id, :type => Integer, :desc => 'Trip comment ID.'
            end
            scope :requires_id do
              desc "Get a specific trip comment"
              get ':id' do
                trip_ticket_comment = TripTicket.find(params[:trip_ticket_id]).trip_ticket_comments.find(params[:id])
                error! "Access Denied", 401 unless current_ability.can?(:show, trip_ticket_comment)
                present trip_ticket_comment, with: Clearinghouse::Entities::V1::TripTicketComment
              end

              desc "Update a trip comment"
              put ':id' do
                trip_ticket_comment = TripTicket.find(params[:trip_ticket_id]).trip_ticket_comments.find(params[:id])
                error! "Access Denied", 401 unless current_ability.can?(:update, trip_ticket_comment)
                if trip_ticket_comment.update_attributes(params[:trip_ticket_comment])
                  present trip_ticket_comment, with: Clearinghouse::Entities::V1::TripTicketComment
                else
                  error!({message: "Could not update trip comment", errors: trip_ticket_comment.errors}, 422)
                end
              end
            end # scope :requires_id
          end # namespace :trip_ticket_comments
        end # scope '/:trip_ticket_id'
      end # namespace :trip_tickets

    end
  end
end
