require 'active_support/concern'

module TripTicketIcons
  extend ActiveSupport::Concern

  included do
    TRIP_TICKET_ICONS_CONFIG_FILE = File.expand_path(File.join('..', 'config', 'icon_mappings.yml'), File.dirname(__FILE__))
    @@trip_ticket_icons_list = YAML::load(File.open(TRIP_TICKET_ICONS_CONFIG_FILE))
  end

  def icon_list
    icons = []
    @@trip_ticket_icons_list.each do |mapping|
      Array(mapping['field_names']).each do |field_name|
        if icon_field_wildcard_match?(mapping, field_name) || icon_field_array_match?(mapping, field_name) ||
          icon_field_hstore_match?(mapping, field_name) || icon_field_match?(mapping, field_name)
          icons << { file: mapping['icon'], alt: alt_text_for(mapping, field_name) }
          break
        end
      end
    end
    icons
  end

  protected

  def icon_field_wildcard_match?(mapping, field_name)
    mapping['match_value'] == '*' && self.send(field_name).present?
  end

  def icon_field_array_match?(mapping, field_name)
    TripTicket::CUSTOMER_IDENTIFIER_ARRAY_FIELD_NAMES.include?(field_name.to_sym) &&
      (self.send(field_name).presence || []).any? {|x| x.include?(mapping['match_value'])}
  end

  def icon_field_hstore_match?(mapping, field_name)
    field_name == 'customer_identifiers' && (customer_identifiers.presence || []).any? {|k,v| v.include?(mapping['match_value'])}
  end

  def icon_field_match?(mapping, field_name)
    (self.send(field_name).presence || '').include?(mapping['match_value'])
  end

  def alt_text_for(mapping, field_name)
    mapping['match_value'] == '*' ? field_name.gsub('_', ' ') : mapping['match_value']
  end
end