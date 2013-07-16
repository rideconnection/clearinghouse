class MobilityAccomodation < ActiveRecord::Base
  belongs_to :provider

  attr_accessible :provider_id, :mobility_impairment

  validates :provider_id, :presence => true
  validates :mobility_impairment, :presence => true
end
