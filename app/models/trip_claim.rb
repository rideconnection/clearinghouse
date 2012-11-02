class TripClaim < ActiveRecord::Base
  belongs_to :trip_ticket
  belongs_to :provider, :foreign_key => :origin_provider_id
  belongs_to :provider, :foreign_key => :claimant_provider_id

  validates_presence_of :claimant_provider_id, :claimant_service_id,
    :origin_provider_id, :rate, :status, :trip_ticket_id

  attr_accessible :claimant_provider_id, :claimant_service_id,
    :origin_provider_id, :rate, :status, :trip_ticket_id

  audited
end
