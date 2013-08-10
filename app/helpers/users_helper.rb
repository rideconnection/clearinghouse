require 'notification_recipients'

module UsersHelper

  def notification_preferences(user)
    html = '<div class="field notification-preferences"><label>Enabled email notifications:</label><ul>'
    NotificationRecipients::NOTIFICATION_TYPES.to_a.each_with_index do |type, index|
      if (user.notification_preferences || []).include?(type.first.to_s)
        html << content_tag(:li, type.last)
      end
    end
    html << '</ul></div>'
    html.html_safe
  end

  def notification_preferences_checkboxes(user)
    html = '<div class="field notification-preferences"><label>Enabled email notifications:</label><div>'
    NotificationRecipients::NOTIFICATION_TYPES.to_a.each_with_index do |type, index|
      html << content_tag(:p) do
        label_tag("user_notification_preferences_#{index}") do
          check_box_tag("user[notification_preferences][]", type.first, (user.notification_preferences || []).include?(type.first.to_s), id: "user_notification_preferences_#{index}") +
          type.last
        end
      end
    end
    html << '</div></div>'
    html.html_safe
  end

end
