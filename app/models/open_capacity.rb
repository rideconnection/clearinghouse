class OpenCapacity < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :arrival_location,   :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :departure_location, :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :service
  has_many :service_requests
  has_many :waypoints

  audited allow_mass_assignment: true
end
