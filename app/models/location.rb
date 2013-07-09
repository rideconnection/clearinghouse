class Location < ActiveRecord::Base
  attr_accessible :address_1, :address_2, :city, :position, :state, :zip
  validates_presence_of :address_1, :city, :state, :zip
  
  def address_and_city(separator = "\n")
    [address_1, address_2, city].reject(&:blank?).map(&:strip).join(separator)
  end
  
  def address_city_and_zip(separator = "\n")
    [address_1, address_2, [city, zip].reject(&:blank?).map(&:strip).join(' ')].reject(&:blank?).map(&:strip).join(separator)
  end
  
  def address_city_state_and_zip(separator = "\n")
    [address_1, address_2, city, [state, zip].reject(&:blank?).map(&:strip).join(' ')].reject(&:blank?).map(&:strip).join(separator)
  end
end
