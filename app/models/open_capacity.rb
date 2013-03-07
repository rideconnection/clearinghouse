class OpenCapacity < ActiveRecord::Base
  belongs_to :arrival_location,   :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :departure_location, :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :service
  has_many :service_requests
  has_many :waypoints

  attr_accessible :arrival_location_id, :arrival_time, :departure_location_id,
    :departure_time, :notes, :scooter_spaces_open, :seats_open,
    :wheelchair_spaces_open, :service_id

  audited
end
