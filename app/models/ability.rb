class Ability
  include CanCan::Ability
 
  # Note: Latter ability rules override previous ones
  # Available roles: :site_admin, :provider_admin, :scheduler, :dispatcher, :csr
 
  def initialize(user)
    user ||= User.new # guest user

    can :read, Provider
    can :read, ProviderRelationship
    can :read, Service
    can :read, TripClaim do |tc|
      user.provider && (user.provider == tc.claimant || user.provider == tc.trip_ticket.originator)
    end
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
        user.provider && user.provider == u.provider
      end
      
      can [:approve, :decline], TripClaim do |tc|
        tc.editable? && (user.provider && tc.trip_ticket && user.provider == tc.trip_ticket.originator)
      end

      can :create, TripTicket
      can [:update, :destroy], TripTicket do |t|
        user.provider && user.provider == t.originator
      end
    elsif user.has_any_role? [:scheduler, :provider_admin]
      can :create, TripClaim do |tc|
        user.provider && user.provider != tc.trip_ticket.originator
      end
      can [:update, :destroy], TripClaim do |tc|
        tc.editable? && (user.provider && user.provider == tc.claimant)
      end
    end

    can :read_multiple, Array do |arr|
      arr.empty? || arr.inject(true){|r, el| r && can?(:read, el)}
    end
  end
end
