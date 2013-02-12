class Location < ActiveRecord::Base
  attr_accessible :address_1, :address_2, :city, :position, :state, :zip
  validates_presence_of :address_1, :city, :state, :zip
  
  def address_and_city
    [address_1, address_2, city].compact.map(&:strip).join("\n")
  end
end
