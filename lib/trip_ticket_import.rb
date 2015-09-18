require 'csv'
#require 'active_model/forbidden_attributes_protection'

class TripTicketImport
  attr_accessor :originator, :row_count, :errors

  class RowError < RuntimeError; end

  def initialize(originator)
    raise ArgumentError unless originator.is_a?(Provider)
    self.originator = originator
  end

  def process(csv_data)
    self.row_count = 0
    self.errors = []

    TripTicket.transaction do
      CSV.parse(csv_data, headers: true, return_headers: false) do |csv_row|
        row = HashWithIndifferentAccess[csv_row.headers.zip(csv_row.fields)]
        row['origin_provider_id'] = originator.id

        begin
          # prepare nested locations and trip results for automatic handling by ActiveRecord
          handle_nested_objects(row)

          handle_date_conversions(row)

          trip = nil
          row_id = row.delete(:id)
          if row_id.present?
            # if imported trips contain an ID, use that to update the existing Clearinghouse trip
            trip = TripTicket.find_by_id(row_id)
            raise RowError, "ID #{row_id} does not match any existing trip ticket ID" if trip.nil?
          elsif row[:origin_trip_id].present? && row[:appointment_time].present?
            # trips on the provider are uniquely identified by trip ID and appointment time so imported rows are considered
            # an update if the originator ID and appointment time match a Clearinghouse trip
            trip = TripTicket.find_by_origin_trip_id_and_appointment_time(row[:origin_trip_id], Time.zone.parse(row[:appointment_time]))
          end

          if trip
            raise RowError, "trip ticket being updated was not created by your provider" if trip.origin_provider_id != originator.id
            trip.update_attributes(row)
          else
            trip = TripTicket.create(row)
          end
          raise RowError, "trip ticket could not be created, error unknown" if trip.nil?
          raise RowError, trip.errors.full_messages.join(', ') unless trip.errors.empty?

        rescue RowError, ActiveModel::ForbiddenAttributesError, ActionController::ParameterMissing => e
          msg = e.message.length > 200 ? (e.message.slice(0, 200) + '...') : e.message
          self.errors << "Row #{row_count + 1}: #{msg}"

        rescue
          self.errors << "Row #{row_count + 1}: unknown error, import cancelled"
          raise
        end

        self.row_count += 1
      end

      errors << "No data rows found, import cancelled" if row_count == 0
      raise ActiveRecord::Rollback, "Errors detected, import cancelled" unless errors.empty?
    end
  end

  protected

  # NOTE this support for nested object import taken directly from the Adapter, we could dry this up with a shared repo

  def handle_nested_objects(row)
    # support nested values for :customer_address, :pick_up_location, :drop_off_location, :trip_result
    # these can be included in the CSV file with the object name prepended, e.g. 'trip_result_outcome'
    # upon import they are removed from the row, then added back as nested objects,
    # e.g.: row['trip_result_attributes'] = { 'outcome' => ... })

    customer_address_hash = nested_object_to_hash(row, 'customer_address_')
    pick_up_location_hash = nested_object_to_hash(row, 'pick_up_location_')
    drop_off_location_hash = nested_object_to_hash(row, 'drop_off_location_')
    trip_result_hash = nested_object_to_hash(row, 'trip_result_')

    normalize_location_coordinates(customer_address_hash)
    normalize_location_coordinates(pick_up_location_hash)
    normalize_location_coordinates(drop_off_location_hash)

    row['customer_address_attributes'] = customer_address_hash if customer_address_hash.present?
    row['pick_up_location_attributes'] = pick_up_location_hash if pick_up_location_hash.present?
    row['drop_off_location_attributes'] = drop_off_location_hash if drop_off_location_hash.present?
    row['trip_result_attributes'] = trip_result_hash if trip_result_hash.present?
  end

  def handle_date_conversions(row)
    # assume any date entered as ##/##/#### is mm/dd/yyyy, convert to dd/mm/yyyy the way Ruby prefers
    row.each do |k,v|
      parts = k.rpartition('_')
      if parts[1] == '_' && ['date', 'time', 'at', 'on', 'dob'].include?(parts[2])
        if v =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})(.*)$/
          new_val = "#{ "%02d" % $2 }/#{ "%02d" % $1 }/#{ $3 }#{ $4 }"
          row[k] = new_val
        end
      end
    end
  end

  def nested_object_to_hash(row, prefix)
    new_hash = {}
    row.select do |k, v|
      if k.to_s.start_with?(prefix)
        new_key = k.to_s.gsub(Regexp.new("^#{prefix}"), '')
        new_hash[new_key] = row.delete(k)
      end
    end
    new_hash
  end

  # normalize accepted location coordinate formats to WKT
  # accepted:
  # location_hash['lat'] and location_hash['lon']
  # location_hash['position'] = "lon lat" (punction ignored except dash, e.g. lon:lat, lon,lat, etc.)
  # location_hash['position'] = "POINT(lon lat)"
  def normalize_location_coordinates(location_hash)
    lat = location_hash.delete('lat')
    lon = location_hash.delete('lon')
    position = location_hash.delete('position')
    new_position = position
    if lon.present? && lat.present?
      new_position = "POINT(#{lon} #{lat})"
    elsif position.present?
      match = position.match(/^\s*([\d\.\-]+)[^\d-]+([\d\.\-]+)\s*$/)
      new_position = "POINT(#{match[1]} #{match[2]})" if match
    end
    location_hash['position'] = new_position if new_position
  end

end