class ServiceRequest < ActiveRecord::Base
  has_one :open_capacity
  has_one :trip_ticket
  has_one :user

  audited allow_mass_assignment: true
end
