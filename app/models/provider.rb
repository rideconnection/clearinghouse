class Provider < ActiveRecord::Base
  has_many :services
  has_one :location, :foreign_key => :address_id
  has_one :user, :foreign_key => :primary_contact_id

  attr_accessible :address_id, :name, :primary_contact_id
end
