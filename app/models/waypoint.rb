class Waypoint < ActiveRecord::Base
  belongs_to :open_capacity
  belongs_to :location, :validate => true, :dependent => :destroy

  attr_accessible :arrival_time, :location_id, :open_capacity_id, :sequence_id
end
