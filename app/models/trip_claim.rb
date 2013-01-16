class TripClaim < ActiveRecord::Base
  belongs_to :trip_ticket
  belongs_to :claimant, :class_name => :Provider, :foreign_key => :claimant_provider_id

  attr_accessible :claimant_provider_id, :claimant_service_id,
    :rate, :status, :trip_ticket_id

  validates_presence_of :claimant_provider_id, :claimant_service_id,
    :rate, :status, :trip_ticket_id

  audited
end
