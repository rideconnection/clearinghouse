class User < ActiveRecord::Base
  belongs_to :provider

  attr_accessible :email, :name, :phone, :title
end
