class Service < ActiveRecord::Base
  
  belongs_to :provider
  has_many :open_capacities
  has_many :operating_hours, :class_name => :OperatingHours
  has_one :funding_source
  has_many :eligibility_requirements

  SERVICE_AREA_TYPES = {
    'none' => 'Do not filter trip tickets based on this service area',
    'pickup' => 'Pickup location must be within service area',
    'dropoff' => 'Drop-off location must be within service area',
    'both' => 'Pickup and drop-off must both be within service area',
    'either' => 'Either pickup or drop-off must be within service area'
  }

  validates_presence_of :name, :provider

  default_scope ->{ order :name }

  def hours_hash
    result = {}
    self.operating_hours.each do |h|
      result[h.day_of_week] = h
    end
    result
  end
end
