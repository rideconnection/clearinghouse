module ApplicationHelper
  def formatted_address_and_city(location)
    unless location.blank?
      raw location.address_and_city('<br/>')
    end
  end
  
  def formatted_address_city_and_zip(location)
    unless location.blank?
      raw location.address_city_and_zip('<br/>')
    end
  end
  
  def display_appointment_time(trip_ticket)
    if !trip_ticket.appointment_time.blank?
      trip_ticket.appointment_time.to_s(:time)
    elsif trip_ticket.scheduling_priority == "pickup" && !trip_ticket.requested_pickup_time.blank?
      trip_ticket.requested_pickup_time.to_s(:time)
    elsif !trip_ticket.requested_drop_off_time.blank?
      trip_ticket.requested_drop_off_time.to_s(:time)
    else
      ""
    end
  end

  def current_page_or_sub?(options)
    url_string = CGI.unescapeHTML(url_for(options))
    if url_string.index("?")
      request_url = request.fullpath
    else
      request_url = request.fullpath.split('?').first
    end
    request_url.starts_with?(url_string)
  end
  
  def main_nav_helper(title, path, li_class = nil)
    opts = { :class => li_class } if li_class.present?
    content_tag(:li, opts) do
      link_to_unless(current_page_or_sub?(path), title, path) do
        link_to(title, path, :class => "active")
      end
    end
  end
  
  def formatted_audit_attribute(attribute, data)
    case attribute.to_sym
    when :provider_white_list, :provider_black_list
      ids = Array(data)
      data = Provider.where(:id => ids).all.collect(&:name).sort.join(', ')
    end
    data.blank? ? "[an empty value]" : data.to_s
  end
  
  def ajaxified_trip_ticket_path(trip_ticket, opts = {})
    opts ||= {}
    ajaxified_trip_ticket_url(trip_ticket, opts.merge({:only_path => true}))
  end
  
  def ajaxified_trip_ticket_url(trip_ticket, opts = {})
    # This is a hack to get around the Rails bugs defined at 
    # https://github.com/rails/rails/issues/5122 and
    # https://github.com/rails/rails/issues/4308
    opts ||= {}
    relative_url_root = opts.delete(:relative_url_root) || 
      Rails.application.config.relative_url_root ||
      ""
    trip_ticket_path = relative_url_root + trip_ticket_url(trip_ticket, only_path: true)
    trip_tickets_url(opts.merge({:anchor => trip_ticket_path}))
  end
end
