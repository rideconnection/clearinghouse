class Service < ActiveRecord::Base
  belongs_to :provider
  has_many :open_capacities
  has_many :operating_hours, :class_name => :OperatingHours
  has_one :funding_source

  attr_accessible :eligibility, :funding_id, :name, :operating_hours_id,
    :rate, :req_min_age, :req_veteran, :service_area
end
