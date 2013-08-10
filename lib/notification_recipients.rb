# model methods for generating lists of notification recipients
# - covers typical situations to keep model code dry
# - respects user preferences for receiving specific notification types
# - makes sure blacklisted provider users do not receive notifications

module NotificationRecipients
  extend ActiveSupport::Concern

  # The NOTIFICATION_TYPES array is used to build the UI for users to enable notification types. The keys are saved
  # as strings in user preferences. When a recipient list is generated, the acts_as_notify options are passed to
  # the functions which include the mailer method about to be invoked -- recipients are filtered to those users who
  # have enabled keys matching the mailer method.
  #
  # Mailer method names need to be unique, even across multiple mailer classes.

  NOTIFICATION_TYPES = {
      trip_created:         'Partner creates a trip ticket',
      trip_rescinded:       'Claimed trip ticket rescinded',
      trip_expired:         'Claimed trip ticket expired',
      claim_for_approval:   'New trip claim awaiting approval',
      claim_auto_approved:  'New trip claim auto-approved',
      claim_approved:       'Trip claim approved',
      claim_declined:       'Trip claim declined',
      claim_rescinded:      'Trip claim rescinded',
      trip_result_created:  'Trip result submitted',
      trip_comment_created: 'Trip comment added'
  }

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
    type = notifier_options[:method].to_sym
    where("(users.notification_preferences @> ?)", "{\"#{type}\"}")
  end
end
