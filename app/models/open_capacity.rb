class OpenCapacity < ActiveRecord::Base
  belongs_to :service
  has_one :location, :foreign_key => :arrival_location_id
  has_one :location, :foreign_key => :departure_location_id
  has_many :waypoints
  has_many :service_requests

  attr_accessible :arrival_location_id, :arrival_time, :departure_location_id,
    :departure_time, :notes, :scooter_spaces_open, :seats_open,
    :wheelchair_spaces_open

  audited
end
