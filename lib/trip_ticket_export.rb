require 'csv'

class TripTicketExport

  attr_accessor :batch_limit, :data, :row_count, :last_exported_timestamp

  def initialize(batch_limit = nil)
    self.batch_limit = batch_limit
  end

  def process(trip_tickets)
    trip_tickets = trip_tickets.limit(batch_limit) if batch_limit.present?
    keys = make_detailed_trip(trip_tickets.first).stringify_keys.keys
    self.row_count = trip_tickets.length
    self.last_exported_timestamp = nil

    self.data = CSV.generate(headers: keys, write_headers: true) do |csv|
      trip_tickets.each do |trip|
        detailed_trip = make_detailed_trip(trip)
        csv << keys.map do |key|
          value = detailed_trip[key]
          case value
          when Array
            # desired format: {"value","value","value"}
            quoted_strings = []
            value.each {|v| quoted_strings << "\"#{v}\""}
            "{#{quoted_strings.join(',')}}"
          when Hash
            # desired format: "eye_color"=>"brown","height"=>"5ft 9in","drivers_license_no"=>"12345"
            quoted_strings = []
            value.each {|k,v| quoted_strings << "\"#{k}\"=>\"#{v}\"" }
            quoted_strings.join(',')
          else
            value
          end
        end
        self.last_exported_timestamp = trip.updated_at if last_exported_timestamp.nil? || trip.updated_at > last_exported_timestamp
      end
    end
  end

  protected

  # NOTE this relies on our Grape API implementation to generate a deeply-nested trip ticket, would be better not to rely on the API code
  def make_detailed_trip(trip_ticket)
    detailed_trip = JSON.parse(Clearinghouse::Entities::V1::TripTicketDetailed.represent(trip_ticket).to_json)
    detailed_trip.delete('trip_ticket_comments')
    detailed_trip.delete('trip_claims')
    flatten_hash(detailed_trip)
  end

  # flatten hash structure, changing keys of nested objects to parentkey_nestedkey
  # arrays of sub-objects will be ignored
  def flatten_hash(hash, prepend_name = nil)
    new_hash = {}
    hash.each do |key, value|
      new_key = [prepend_name, key.to_s].compact.join('_')
      case value
        when Hash
          if value['id'].present?
            # only flatten sub-hashes that are objects with an ID
            new_hash.merge!(flatten_hash(value, new_key))
          else
            new_hash[new_key] = value
          end
        when Array
          hash_array = value.index{|x| x.is_a?(Hash) }.present?
          new_hash[new_key] = value unless hash_array
        else
          new_hash[new_key] = value
      end
    end
    new_hash
  end

end