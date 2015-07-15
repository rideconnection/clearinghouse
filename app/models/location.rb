class Location < ActiveRecord::Base
  validates_presence_of :address_1, :city, :state, :zip

  audited allow_mass_assignment: true

  attr_writer :latitude, :longitude

  before_validation :normalize_coordinates

  def latitude
    @latitude || position.try(:y)
  end

  def longitude
    @longitude || position.try(:x)
  end

  def address_and_city(separator = "\n")
    [address_1, address_2, city].reject(&:blank?).map(&:strip).join(separator)
  end
  
  def address_city_and_zip(separator = "\n")
    [address_1, address_2, [city, zip].reject(&:blank?).map(&:strip).join(' ')].reject(&:blank?).map(&:strip).join(separator)
  end
  
  def address_city_state_and_zip(separator = "\n")
    [address_1, address_2, city, [state, zip].reject(&:blank?).map(&:strip).join(' ')].reject(&:blank?).map(&:strip).join(separator)
  end

  protected

  def normalize_coordinates
    if @latitude.present? && @longitude.present?
      self.position = "POINT (#{@longitude} #{@latitude})"
    end
  end
end
