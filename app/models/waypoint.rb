class Waypoint < ActiveRecord::Base
  belongs_to :open_capacity
  has_one :location

  attr_accessible :arrival_time, :location_id, :open_capacity_id, :sequence_id
end
