class Location < ActiveRecord::Base
  attr_accessible :address_1, :address_2, :city, :position, :state, :zip
end
