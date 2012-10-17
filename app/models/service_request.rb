class ServiceRequest < ActiveRecord::Base
  has_one :open_capacity
  has_one :trip_ticket
  has_one :user

  attr_accessible :notes, :open_capacity_id, :status, :trip_ticket_id, :user_id

  audited
end
