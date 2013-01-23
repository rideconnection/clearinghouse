class ProviderRelationship < ActiveRecord::Base
  belongs_to :requesting_provider, 
    :foreign_key => "requesting_provider_id",
    :class_name => "Provider"

  belongs_to :cooperating_provider, 
    :foreign_key => "cooperating_provider_id",
    :class_name => "Provider"

  validates :requesting_provider_id, :presence => true

  validates :cooperating_provider_id, :presence => true

  attr_accessible :approved_at, :automatic_cooperator_approval, 
    :automatic_requester_approval, :cooperating_provider_id, 
    :requesting_provider_id, :requesting_provider, :cooperating_provider

  validate :must_reference_different_providers

  validate :must_be_unique_relationship, :on => :create 
  
  scope :approved, where("approved_at IS NOT NULL")

  def name
    name_1 = requesting_provider.name
    name_2 = cooperating_provider.name
    "Partnership between #{name_1} and #{name_2}"
  end

  def approve!
    self.approved_at = Time.now
    save!
  end

  def includes_user?(user)
    user.provider == cooperating_provider || user.provider == requesting_provider
  end

  def partner_for_provider(provider)
    if cooperating_provider == provider
      requesting_provider
    elsif requesting_provider == provider
      cooperating_provider
    else
      nil
    end
  end
  
  def approved?
    approved_at?
  end
  
  def self.relationship_exists?(provider_1, provider_2, only_approved = false)
    self.partner_ids_for_provider(provider_1, only_approved).include? provider_2.id
  end
  
  def self.partners_for_provider(provider, only_approved = true)
    Provider.where(:id => self.partner_ids_for_provider(provider, only_approved))
  end

  def self.partner_ids_for_provider(provider, only_approved = true)
    (only_approved ? self.approved : self).
      select([:requesting_provider_id, :cooperating_provider_id]).
      where(%Q{(requesting_provider_id = ? OR cooperating_provider_id = ?)}, provider.id, provider.id).
      collect{|r| r.requesting_provider_id == provider.id ? r.cooperating_provider_id : r.requesting_provider_id }
  end

  private

  def must_reference_different_providers
    if requesting_provider_id == cooperating_provider_id
      errors.add(:base, "Must select two different providers") 
    end
  end

  def must_be_unique_relationship
    if requesting_provider.present? && cooperating_provider.present? && ProviderRelationship.relationship_exists?(requesting_provider, cooperating_provider)
      errors.add(:base, 
        "There is already a relationship between these providers")
    end
  end
end
