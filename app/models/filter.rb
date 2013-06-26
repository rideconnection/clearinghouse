class Filter < ActiveRecord::Base
  belongs_to :user

  attr_accessible :name, :data

  serialize :data

  validates_presence_of :user_id, :name, :data
  validates_uniqueness_of :name, :scope => :user_id
end
