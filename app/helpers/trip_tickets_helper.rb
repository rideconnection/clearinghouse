module TripTicketsHelper
  def providers_from_white_black_list(provider_ids)
    raw Provider.where(:id => provider_ids).all.collect{|p| link_to p.name, provider_path(p)}.join(', ')
  end
  
  def customer_age(dob)
    now = Time.zone.now
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end
  
  def formatted_customer_identifiers(identifier_array)
    unless identifier_array.blank?
      simple_format identifier_array.reject(&:blank?).map(&:strip).join("\n")
    end
  end
  
  def load_time_warning(customer_boarding_time)
    if customer_boarding_time > 3
      raw image_tag('icon02.png', width: 13, height: 13, alt: '')
    end
  end
  
  def unload_time_warning(customer_deboarding_time)
    if customer_deboarding_time > 3
      raw image_tag('icon02.png', width: 13, height: 13, alt: '')
    end
  end
  
  def load_unload_time_warning(customer_boarding_time, customer_deboarding_time)
    if customer_boarding_time > 3 || customer_deboarding_time > 3
      raw image_tag('icon02.png', width: 13, height: 13, alt: '')
    end
  end
  
  def formatted_allowed_time_variance(allowed_time_variance)
    if allowed_time_variance > 0
      " +/- #{allowed_time_variance}"
    end
  end
  
  def formatted_activity_line(activity)
    activity_type = if activity.respond_to?(:auditable) 
      if activity.audited_changes.first[0] == 'rescinded'
        activity.audited_changes.first[1][1] ? 'Rescinded' : 'Unrescinded'
      elsif activity.audited_changes.first[0] == 'expired'
        activity.audited_changes.first[1][1] ? 'Expired' : 'Unexpired'
      else
        case activity.action
        when "create"
          "Created"
        when "update"
          "Updated"
        else
          activity.action.capitalize
        end
      end
    else
      activity.class.name.underscore.gsub("trip_", "").gsub("ticket_", "").capitalize
    end

    activity_action = case activity
      when TripResult 
        activity.outcome
      when Audited::Adapters::ActiveRecord::Audit
        activity.try(:auditable_type).to_s.titleize
      else
        ""
    end

    activity_user = if activity.respond_to?(:user)
      activity.user.try(:display_name)
    elsif activity.is_a?(TripClaim)
      activity.claimant.name
    elsif activity.respond_to?(:auditable)
      activity.audits.first.try(:user).try(:display_name)
    else
      ""
    end

    description = "#{activity_type} #{activity_action}#{activity_user.blank? ? '' : ' - '}#{activity_user}"

    if activity.is_a?(TripClaim) and can?(:rescind, activity) and activity.editable?
      rescind_link = rescind_trip_ticket_trip_claim_path(activity.trip_ticket, activity)
      edit_link = edit_trip_ticket_trip_claim_path(activity.trip_ticket, activity)
      description = link_to(description, edit_link, {class: "claim-rescind no-clickify", data: {rescind: rescind_link}})
    end

    raw(
      "<td class='activity-info' title=\"#{activity.created_at.strftime('%a %Y-%m-%d %I:%M %P')}\">#{activity.created_at.strftime("%l:%M %p")}</td>" +
      "<td class='activity-info'>#{activity.created_at.strftime("%b %d")}</td>" + 
      "<td>#{description}</td>"
    )
  end
  
  def formatted_activity_type(activity)
    activity.class.name.demodulize.underscore
  end
  
  def activity_path(activity)
    if activity.is_a?(TripResult) 
      trip_ticket_path(activity.trip_ticket) + '/trip_result'
    elsif activity.respond_to?(:auditable)
      trip_ticket_audits_path(activity.auditable)
    else
      [activity.trip_ticket, activity]
    end
  end

  # this converts trip status to a simplified snake-cased form in a consistent way
  def underscore_status(trip_status)
    if trip_status =~ /Approved$/
      'approved'
    elsif trip_status =~ /Pending$/
      'pending'
    else
      trip_status.downcase.gsub(' ', '_')
    end
  end

  def eligibility_autocomplete_values
    TripTicket.unscoped.accessible_by(current_ability).pluck('DISTINCT unnest(trip_tickets.customer_eligibility_factors)').reject {|x| x.blank?}.sort
  end

  def service_level_autocomplete_values
    TripTicket.unscoped.accessible_by(current_ability).pluck(:customer_service_level).reject {|x| x.blank?}.sort
  end

  def wkt_point_from_location(location)
    position = location.try(:position)
    position.presence && "POINT (#{position.x} #{position.y})"
  end
end
