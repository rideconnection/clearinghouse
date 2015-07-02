require 'notification_recipients'

class TripResult < ActiveRecord::Base
  include NotificationRecipients
  include ActiveModel::ForbiddenAttributesProtection

  OUTCOMES = ["Completed", "No-Show", "Cancelled"]

  audited

  belongs_to :trip_ticket, :touch => true
  has_one :trip_claim

  acts_as_notifier do
    after_create do
      notify ->(opts){ provider_users([trip_ticket.originator, claimant], opts) }, method: :trip_result_created
    end
  end

  validates :trip_ticket_id,
    :presence => true,
    :uniqueness => true

  validates :outcome,
    :presence => true,
    :inclusion => { :in => OUTCOMES }

  validate :ensure_trip_ticket_is_approved

  def claimant
    trip_ticket.approved_claim.try(:claimant)
  end

  private

  def ensure_trip_ticket_is_approved
    unless trip_ticket.try(:approved?)
      errors.add(:trip_ticket, "must be approved")
    end
  end
end
