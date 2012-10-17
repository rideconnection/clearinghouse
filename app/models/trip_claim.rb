class TripClaim < ActiveRecord::Base
  belongs_to :trip_ticket
  belongs_to :provider, :foreign_key => :origin_provider_id
  belongs_to :provider, :foreign_key => :claimant_provider_id

  attr_accessible :claimant_provider_id, :origin_provider_id, :status,
    :trip_ticket_id

  audited
end
