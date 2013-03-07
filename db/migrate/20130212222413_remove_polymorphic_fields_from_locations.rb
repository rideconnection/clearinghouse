class RemovePolymorphicFieldsFromLocations < ActiveRecord::Migration

  class Location < ActiveRecord::Base; end

  class TripTicket < ActiveRecord::Base; end

  class Provider < ActiveRecord::Base; end

  class OpenCapacity < ActiveRecord::Base; end

  class Waypoint < ActiveRecord::Base; end

  def up
    transaction do
      Location.all.each do |location|
        unless location.addressable_type.nil?
          o = location.addressable_type.constantize.find(location.addressable_id)
      
          case location.addressable_type
          when 'TripTicket'
            if o.customer_address_id.nil?
               o.customer_address_id = location.id
            elsif o.pick_up_location_id.nil?
              o.pick_up_location_id = location.id
            elsif o.drop_off_location_id.nil?
              o.drop_off_location_id = location.id
            end
          when 'Provider'
            o.address_id = location.id
          when 'OpenCapacity'
            if o.arrival_location_id.nil?
               o.arrival_location_id = location.id
            elsif o.departure_location_id.nil?
              o.departure_location_id = location.id
            end
          when 'Waypoint'
            o.location_id = location.id
          end

          o.save!
        end
      end
    
      remove_index :locations, [:addressable_id, :addressable_type]
      remove_column :locations, :addressable_type
      remove_column :locations, :addressable_id
    end
  end

  def down
    transaction do
      add_column :locations, :addressable_id, :integer
      add_column :locations, :addressable_type, :string
      add_index :locations, [:addressable_id, :addressable_type]
    
      TripTicket.all.each do |o|
        [:customer_address_id, :pick_up_location_id, :drop_off_location_id].each do |location_type_sym|
          location = Location.find(o.send(location_type_sym))
          location.addressable_id = o.id
          location.addressable_type = 'TripTicket'
          location.save!
        end
      end
    
      Provider.all.each do |o|
        location = Location.find(o.address_id)
        location.addressable_id = o.id
        location.addressable_type = 'Provider'
        location.save!
      end
    
      OpenCapacity.all.each do |o|
        [:arrival_location, :departure_location].each do |location_type_sym|
          location = Location.find(o.send(location_type_sym))
          location.addressable_id = o.id
          location.addressable_type = 'OpenCapacity'
          location.save!
        end
      end

      Waypoint.all.each do |o|
        location = Location.find(o.address_id)
        location.addressable_id = o.id
        location.addressable_type = 'Waypoint'
        location.save!
      end
    end
  end
end
