class Service < ActiveRecord::Base
  belongs_to :provider
  has_many :open_capacities
  has_many :operating_hours, :class_name => :OperatingHours
  has_one :funding_source
  has_many :eligibility_requirements
  has_many :mobility_accommodations

  SERVICE_AREA_TYPES = {
    'none' => 'Do not filter trip tickets based on this service area',
    'pickup' => 'Pickup location must be within service area',
    'dropoff' => 'Drop-off location must be within service area',
    'both' => 'Pickup and drop-off must both be within service area'
  }

  attr_accessible :eligibility, :funding_id, :name, :operating_hours_id,
    :rate, :req_min_age, :req_veteran, :service_area, :service_area_type, :provider_id

  validates_presence_of :name, :provider

  default_scope order(:name)

  def hours_hash
    result = {}
    self.operating_hours.each do |h|
      result[h.day_of_week] = h
    end
    result
  end
end
