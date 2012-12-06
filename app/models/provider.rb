class Provider < ActiveRecord::Base
  has_many :services
  has_many :nonces
  has_one :location, :foreign_key => :address_id
  has_one :user, :foreign_key => :primary_contact_id

  attr_accessible :address_id, :name, :primary_contact_id
  
  after_create :generate_initial_api_keys
  
  validates :api_key, uniqueness: true, presence: {on: :update}
  validates :private_key, presence: {on: :update}
  
  def regenerate_keys!(force = true)
    generate_api_key!     if force || !self.api_key.present?
    generate_private_key! if force || !self.private_key.present?
  end
  
  private
  
  def generate_api_key!
    begin
      api_key = SecureRandom.hex
    end while self.class.exists?(api_key: api_key)
    self.update_attribute(:api_key, api_key)
  end
  
  def generate_private_key!
    self.update_attribute(:private_key, SecureRandom.hex)
  end

  def generate_initial_api_keys
    generate_api_key! unless self.api_key.present?
    generate_private_key! unless self.private_key.present?
  end  
end
