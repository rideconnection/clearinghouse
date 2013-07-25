class MobilityAccommodation < ActiveRecord::Base
  belongs_to :service

  attr_accessible :mobility_impairment

  validates :service_id, :presence => true
  validates :mobility_impairment, :presence => true
end
