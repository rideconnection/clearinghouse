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

  private

  def must_reference_different_providers
    if requesting_provider_id == cooperating_provider_id
      errors.add(:base, "Must select two different providers") 
    end
  end

  def must_be_unique_relationship
    if relationships_with_the_same_providers.any?
      errors.add(:base, 
        "There is already a relationship between these providers")
    end
  end

  def relationships_with_the_same_providers
    ProviderRelationship.where(
      %Q{
        (requesting_provider_id = ? AND cooperating_provider_id = ?) OR
        (requesting_provider_id = ? AND cooperating_provider_id = ?) },
      requesting_provider_id, cooperating_provider_id,
      cooperating_provider_id, requesting_provider_id
    )
  end
end
