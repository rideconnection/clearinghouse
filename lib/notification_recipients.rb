# model methods for generating lists of notification recipients
# - covers typical situations to keep model code dry
# - respects user preferences for receiving specific notification types
# - makes sure blacklisted provider users do not receive notifications

module NotificationRecipients
  extend ActiveSupport::Concern

  # The NOTIFICATION_TYPES array is used to build the UI for users to enable notification types. The method names are
  # saved as strings in user preferences. When a recipient list is generated, the acts_as_notify options are passed to
  # the functions which include the mailer method about to be invoked -- recipients are filtered to those users who
  # have enabled that method.
  #
  # Method names should be kept unique. If method names need to overlap, the mailer class could be added to distinguish.

  NOTIFICATION_TYPES = [
    { description: 'Partner creates a trip ticket',     method: :trip_created },
    { description: 'Claimed trip ticket rescinded',     method: :trip_rescinded },
    { description: 'Claimed trip ticket expired',       method: :trip_expired },
    { description: 'New trip claim awaiting approval',  method: :claim_for_approval },
    { description: 'New trip claim auto-approved',      method: :claim_auto_approved },
    { description: 'Trip claim approved',               method: :claim_approved },
    { description: 'Trip claim declined',               method: :claim_declined },
    { description: 'Trip claim rescinded',              method: :claim_rescinded },
    { description: 'Trip result submitted',             method: :trip_result_created },
    { description: 'Trip comment added',                method: :trip_comment_created }
  ]

  protected

  def provider_users(provider, notifier_options)
    provider_ids = (provider.is_a?(Array) ? provider : [provider]).compact.map {|p| p.id }
    users_by_provider_id(provider_ids, notifier_options)
  end

  def partner_users(trip_ticket, notifier_options)
    provider_ids = trip_ticket.originator.approved_partners.pluck(:id)
    provider_ids &= trip_ticket.provider_white_list if trip_ticket.provider_white_list.present?
    provider_ids -= trip_ticket.provider_black_list if trip_ticket.provider_black_list.present?
    users_by_provider_id(provider_ids, notifier_options)
  end

  def claimant_users(trip_ticket, notifier_options)
    provider_ids = trip_ticket.trip_claims.where(status: TripClaim::ACTIVE_STATUS).pluck(:claimant_provider_id)
    users_by_provider_id(provider_ids, notifier_options)
  end

  def originator_and_claimant_users(trip_ticket, notifier_options)
    provider_ids = trip_ticket.trip_claims.where(status: TripClaim::ACTIVE_STATUS).pluck(:claimant_provider_id)
    provider_ids << trip_ticket.origin_provider_id
    users_by_provider_id(provider_ids, notifier_options)
  end

  # filtering

  def users_by_provider_id(provider_ids, notifier_options)
    User.unscoped.where(provider_id: provider_ids).apply_filters(notifier_options)
  end

  def apply_filters(notifier_options)
    for_notification_type(notifier_options).pluck(:email)
  end

  def for_notification_type(notifier_options)
    type = notification_type(notifier_options)
    where("(users.notification_preferences @> ?)", "{\"#{type}\"}")
  end

  def notification_type(notifier_options)
    notifier_options ||= {}
    # note: mailer class not needed to identify a type, if we keep method names unique
    method = notifier_options[:method].to_sym
    NOTIFICATION_TYPES.select {|type| type[:method] == method }.first
  end
end
