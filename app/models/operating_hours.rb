class OperatingHours < ActiveRecord::Base
  belongs_to :service

  attr_accessible :close_time, :day_of_week, :open_time, :service_id
end
