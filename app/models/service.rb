class Service < ActiveRecord::Base
  belongs_to :provider
  has_many :open_capacities
  has_many :operating_hours
  has_one :funding_source

  attr_accessible :funding_id, :name, :operating_hours_id,
    :rate, :req_min_age, :req_veteran, :service_area
end
