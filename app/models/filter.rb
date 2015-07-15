class Filter < ActiveRecord::Base
  
  belongs_to :user

  serialize :data

  validates_presence_of :user_id, :name, :data
  validates_uniqueness_of :name, :scope => :user_id
end
