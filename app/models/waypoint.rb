class Waypoint < ActiveRecord::Base
  belongs_to :open_capacity
  belongs_to :location, :validate => true, :dependent => :destroy
end
