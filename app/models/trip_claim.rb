class TripClaim < ActiveRecord::Base
  belongs_to :trip_ticket
  belongs_to :claimant, :class_name => :Provider, :foreign_key => :claimant_provider_id
  
  STATUS = {
    :pending => 0,
    :approved => 1,
    :declined => -1
  }

  attr_accessible :claimant_customer_id, :claimant_provider_id, :claimant_service_id, 
    :claimant_trip_id, :status, :trip_ticket_id, :proposed_pickup_time, :proposed_fare, 
    :notes

  validates_presence_of :claimant_provider_id, :status, :trip_ticket_id, 
    :proposed_pickup_time
    
  validate :trip_ticket_is_not_claimed, :one_claim_per_trip_ticket_per_claimant

  audited
  
  after_initialize do
    if self.new_record?
      self.status = STATUS[:pending]
    end
  end
  
  after_create do
    self.approve! if self.can_be_auto_approved?
  end

  def approve!
    self.status = STATUS[:approved]
    save!
    trip_ticket.trip_claims.where('id != ?', self.id).update_all(:status => STATUS[:declined])
  end
  
  def approved?
    self.status == STATUS[:approved]
  end
  
  def decline!
    self.status = STATUS[:declined]
    save!
  end
  
  def editable?
    (self.status.blank? || self.status == STATUS[:pending]) && (!self.trip_ticket.present? || !self.trip_ticket.claimed?)
  end
  
  def can_be_auto_approved?
    self.claimant.can_auto_approve_for?(self.trip_ticket.originator)
  end
  
  private
  
  def trip_ticket_is_not_claimed
    if self.trip_ticket && self.trip_ticket.claimed?
      errors.add(:base, "You cannot create or modify a claim on a trip ticket once it has been claimed")
    end
  end

  def one_claim_per_trip_ticket_per_claimant
    if !self.persisted? && self.trip_ticket.present? && self.claimant.present? && self.trip_ticket.includes_claim_from?(self.claimant)
      errors.add(:base, "You may only create one claim per ticket per provider")
    end
  end
end
