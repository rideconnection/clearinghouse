class Provider < ActiveRecord::Base
  has_many :services
  has_many :nonces
  has_many :users
  belongs_to :address, :class_name => :Location, :validate => true, :dependent => :destroy
  belongs_to :primary_contact, :class_name => :User
  has_many :trip_tickets, :foreign_key => :origin_provider_id
  has_many :trip_claims, :foreign_key => :claimant_provider_id
  
  # :address_attributes is needed to support mass-assignment of nested attrs
  attr_accessible :active, :address, :address_attributes, :name,
                  :primary_contact_id
  accepts_nested_attributes_for :address
  
  after_create :generate_initial_api_keys
  after_save :update_user_provider
  
  validates :api_key, uniqueness: true, presence: {on: :update}
  validates :private_key, presence: {on: :update}
  validates_presence_of :name, :address, :primary_contact_id
  
  def approved_partnerships
    partnerships = ProviderRelationship.where(
      %Q{
        (requesting_provider_id = ? OR cooperating_provider_id = ?) 
        AND approved_at IS NOT NULL
      },
      id, id
    )
    partnerships.includes(:cooperating_provider, :requesting_provider)
  end

  def pending_partnerships_initiated_by_it
    partnerships = ProviderRelationship.where(
      :requesting_provider_id => id, 
      :approved_at => nil)
    partnerships.includes(:cooperating_provider, :requesting_provider)
  end

  def partnerships_awaiting_its_approval
    partnerships = ProviderRelationship.where(
      :cooperating_provider_id => id, 
      :approved_at => nil)
    partnerships.includes(:cooperating_provider, :requesting_provider)
  end
  
  def can_auto_approve_for?(provider)
    !!((r = ProviderRelationship.find_approved_relationship_between(self, provider)) && r.provider_can_auto_approve?(self))
  end

  def regenerate_keys!(force = true)
    generate_api_key!     if force || !self.api_key.present?
    generate_private_key! if force || !self.private_key.present?
  end
  
  def generate_nonce
    begin
      nonce = SecureRandom.hex
    end while self.nonces.exists?(nonce: nonce)
    nonce
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

  # If a user has been made primary contact of this provider, then the user
  # should be a member of this provider.
  def update_user_provider
    self.primary_contact.provider = self
    self.primary_contact.save!
  end

end
