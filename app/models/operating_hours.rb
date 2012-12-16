class OperatingHours < ActiveRecord::Base
  belongs_to :service

  attr_accessible :close_time, :day_of_week, :open_time, :service

  validates_presence_of :day_of_week, :service
  validate :enforce_hour_sanity

  default_scope order(:day_of_week)

  START_OF_DAY = Time.zone.parse('05:00').time_of_day
  END_OF_DAY = Time.zone.parse('03:00').time_of_day

  # Notes:
  # - open_time and close_time should use time_of_day
  # - open_time == 0:00 and close_time == 0:00 represents 24-hours
  # - If closed, then hours should be null.

  def make_closed!
    self.open_time = nil
    self.close_time = nil
  end

  def is_closed?
    self.open_time.nil? and self.close_time.nil?
  end

  def make_24_hours!
    t = Time.zone.parse('00:00Z').time_of_day
    self.open_time = t
    self.close_time = t
  end

  def is_24_hours?
    t = Time.zone.parse('00:00Z').time_of_day
    open_time == t and close_time == t
  end

  def is_regular_hours?
    !is_closed? and !is_24_hours?
  end

  def enforce_hour_sanity
    # close_time > END_OF_DAY to allow hours such as 12:00pm - 3:00am (next day)
    if is_regular_hours? and open_time >= close_time and close_time > END_OF_DAY
      errors.add(:close_time, 'must be later than open time.')
    end
  end
end
