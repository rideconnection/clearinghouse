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
    self.approved_at = Time.zone.now
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
  
  def self.relationship_exists?(provider_1, provider_2)
    self.find_any_relationship_between(provider_1, provider_2).present?
  end
  
  def self.partner_ids_for_provider(provider, only_approved = true)
    (only_approved ? self.approved : self).
      select([:requesting_provider_id, :cooperating_provider_id]).
      where(%Q{(requesting_provider_id = ? OR cooperating_provider_id = ?)}, provider.id, provider.id).
      collect{|r| r.requesting_provider_id == provider.id ? r.cooperating_provider_id : r.requesting_provider_id }
  end
  
  def self.find_approved_relationship_between(provider_1, provider_2)
    self.approved.where(
      %Q{(requesting_provider_id = ? AND cooperating_provider_id = ?) OR (requesting_provider_id = ? AND cooperating_provider_id = ?)}, 
      provider_1.id, provider_2.id, provider_2.id, provider_1.id
    ).limit(1).first
  end

  def self.find_any_relationship_between(provider_1, provider_2)
    self.where(
      %Q{(requesting_provider_id = ? AND cooperating_provider_id = ?) OR (requesting_provider_id = ? AND cooperating_provider_id = ?)}, 
      provider_1.id, provider_2.id, provider_2.id, provider_1.id
    ).limit(1).first
  end
  
  def provider_can_auto_approve?(provider)
    if provider == self.requesting_provider
      self.automatic_requester_approval
    elsif provider == self.cooperating_provider
      self.automatic_cooperator_approval
    else
      false
    end
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
