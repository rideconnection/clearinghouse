require 'notification_recipients'

class TripTicketComment < ActiveRecord::Base
  include NotificationRecipients

  belongs_to :trip_ticket, :touch => true
  belongs_to :user
  
  audited

  acts_as_notifier do
    after_create do
      notify ->(opts){ originator_and_claimant_users(trip_ticket, opts) }, method: :trip_comment_created
    end
  end

  attr_accessible :body, :trip_ticket_id, :user_id
  
  validates_presence_of :body, :trip_ticket_id, :user_id
  
  default_scope order('created_at ASC')
end
