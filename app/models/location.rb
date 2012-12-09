class Location < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  attr_accessible :address_1, :address_2, :city, :position, :state, :zip
  validates_presence_of :address_1, :city, :state, :zip
end
