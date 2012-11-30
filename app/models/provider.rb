class Provider < ActiveRecord::Base
  has_many :services
  has_one :location, :foreign_key => :address_id
  has_one :user, :foreign_key => :primary_contact_id

  attr_accessible :address_id, :name, :primary_contact_id
  
  after_create :generate_initial_api_key
  
  validates :api_key, :uniqueness => true, :presence => {:on => :update}
  
  def generate_api_key!
    begin
      api_key = SecureRandom.hex
    end while self.class.exists?(:api_key => api_key)
    self.update_attribute(:api_key, api_key)
  end
  
  private

  def generate_initial_api_key
    self.generate_api_key! unless self.api_key.present?
  end
end
