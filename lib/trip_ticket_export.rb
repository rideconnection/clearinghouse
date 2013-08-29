require 'csv'

class TripTicketExport

  attr_accessor :batch_limit, :data, :row_count, :last_import_time

  def initialize(batch_limit = nil)
    self.batch_limit = batch_limit
  end

  def process(trip_tickets)
    trip_tickets = trip_tickets.limit(batch_limit) if batch_limit.present?
    keys = make_detailed_trip(trip_tickets.first).stringify_keys.keys
    self.row_count = trip_tickets.length
    self.last_import_time = nil

    self.data = CSV.generate(headers: keys, write_headers: true) do |csv|
      trip_tickets.each do |trip|
        detailed_trip = make_detailed_trip(trip)
        csv << keys.map { |key| detailed_trip[key] }
        self.last_import_time = trip.updated_at if last_import_time.nil? || trip.updated_at > last_import_time
      end
    end
  end

  protected

  # TODO this relies on our Grape API implementation to generate a deeply-nested trip ticket, would be better to just combine attributes explicitly
  def make_detailed_trip(trip_ticket)
    flatten_hash(JSON.parse(Clearinghouse::Entities::V1::TripTicketDetailed.represent(trip_ticket).to_json))
  end

  # flatten hash structure, changing keys of nested objects to parentkey_nestedkey
  # arrays of sub-objects will be ignored
  def flatten_hash(hash, prepend_name = nil)
    new_hash = {}
    hash.each do |key, value|
      new_key = [prepend_name, key.to_s].compact.join('_')
      case value
        when Hash
          new_hash.merge!(flatten_hash(value, new_key))
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