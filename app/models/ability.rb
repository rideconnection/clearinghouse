class Ability
  include CanCan::Ability
 
  # Note: Latter ability rules override previous ones
  # Available roles: :site_admin, :provider_admin, :scheduler, :dispatcher, :csr
 
  def initialize(user)
    user ||= User.new # guest user
     
    can :read, Provider
    can :read, ProviderRelationship
    can :read, Service
    can :read, TripTicket
    can :read, User
    can :update, User, :id => user.id

    if user.has_role? :site_admin
      can :manage, :all
    elsif user.has_role? :provider_admin
      can [:update, :keys, :reset_keys], Provider do |p|
        user.provider == p
      end

      can :create, ProviderRelationship
      can :manage, ProviderRelationship do |relationship|
        relationship.includes_user? user
      end
      can :activate, ProviderRelationship do |relationship|
        relationship.cooperating_provider == user.provider
      end

      can :create, Service
      can :update, Service do |s|
        user.provider == s.provider
      end
      
      can :create, User
      can [:update, :activate, :deactivate, :set_provider_role], User do |u|
        user.provider and user.provider == u.provider
      end
      
      can :create, TripTicket
      can :update, TripTicket do |t|
        user.provider and user.provider == t.originator
      end
    end
  end
end
