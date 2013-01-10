module ProviderRelationshipsHelper
  def requester_approval_label_for(relationship)
    "Automatically approve #{relationship.requesting_provider.name}'s tickets?"
  end

  def cooperator_approval_label_for(relationship)
    "Automatically approve #{relationship.cooperating_provider.name}'s tickets?"
  end
end
