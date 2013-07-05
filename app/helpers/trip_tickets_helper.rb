module TripTicketsHelper
  def providers_from_white_black_list(provider_ids)
    raw Provider.where(:id => provider_ids).all.collect{|p| link_to p.name, provider_path(p)}.join(', ')
  end
  
  def customer_age(dob)
    now = Time.now.utc.to_date
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
    raw "<span title=\"#{activity.created_at.strftime('%a %Y-%m-%d %I:%M %P')}\">#{activity.created_at.strftime("%l:%M %p | %b %d")}</span> #{activity.class.name.underscore.gsub("trip_", "").gsub("ticket_", "").capitalize} - #{activity.audits.first.try(:user).try(:display_name)}"
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
end
