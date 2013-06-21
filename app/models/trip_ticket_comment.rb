class TripTicketComment < ActiveRecord::Base
  belongs_to :trip_ticket, :touch => true
  belongs_to :user
  
  audited
  
  attr_accessible :body, :trip_ticket_id, :user_id
  
  validates_presence_of :body, :trip_ticket_id, :user_id
end
