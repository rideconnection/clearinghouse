class ServiceRequest < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  has_one :open_capacity
  has_one :trip_ticket
  has_one :user

  # attr_accessible :notes, :open_capacity_id, :status, :trip_ticket_id, :user_id

  audited allow_mass_assignment: true
end
