class Ability
  include CanCan::Ability
 
  # Note: Latter ability rules override previous ones

  # Available roles: :site_admin, :provider_admin, :scheduler, :dispatcher, :csr
  
  # In block definitions with 3 arguments, the last argument is used by 
  # accessible_by to find resources, while the block is used to validate 
  # individual resources. See also:
  # https://github.com/ryanb/cancan/wiki/Defining-Abilities-with-Blocks
 
  def initialize(user)
    user ||= User.new # guest user

    if user.has_role? :site_admin
      # Site admins have free reign
      can :manage, :all
    else
      # Users can read their own provider or providers they have an approved relationship with
      can :read, Provider, :id => [user.provider_id] + ProviderRelationship.partner_ids_for_provider(user.provider)
      
      # Users can read provider relationships that their own provider belongs to
      can :read, ProviderRelationship, ['cooperating_provider_id = ? OR requesting_provider_id = ?', user.provider_id, user.provider_id] do |pr|
        pr.includes_user?(user)
      end

      # Users can read services belonging to their own provider
      can :read, Service, :provider_id => user.provider_id

      # Users can access a list trip claims belonging to their own provider, and can additionally read individual trip claims associated with trip_tickets that belong to their own provider
      can :read, TripClaim, TripClaim.joins(:trip_ticket).where('trip_claims.claimant_provider_id = ? OR trip_tickets.origin_provider_id = ?', user.provider_id, user.provider_id) do |tc|
        tc.claimant_provider_id == user.provider_id || tc.trip_ticket.origin_provider_id == user.provider_id
      end

      # Users can access a list trip ticket comments associated with trip tickets belonging to their own provider
      can :read, TripTicketComment, :trip_ticket => { :origin_provider_id => user.provider_id }

      # Users can read trip tickets belonging to their own provider or providers they have an approved relationship with
      can :read, TripTicket, :origin_provider_id => [user.provider_id] + ProviderRelationship.partner_ids_for_provider(user.provider)
      
      # Users can read and update their own record
      can [:read, :update], User, :id => user.id

      if user.has_role? :provider_admin
        # Provider admins can update and work with the keys of their own provider
        can [:update, :keys, :reset_keys], Provider, :id => user.provider_id

        # Provider admins can update and destroy provider relationships that their own provider belongs to
        can [:update, :destroy], ProviderRelationship do |pr|
          pr.includes_user?(user)
        end
        
        # Provider admins can activate (aka approve) provider relationships sent to their own provider
        can :activate, ProviderRelationship, :cooperating_provider_id => user.provider_id
        
        # Provider admins can create provider relationships originating from their own provider
        can :create, ProviderRelationship, :requesting_provider_id => user.provider_id
      
        # Provider admins can create and update services belonging to their own provider
        can [:create, :update], Service, :provider_id => user.provider_id

        # Provider admins can read, create, update, activate, deactivate, and set the role of users belonging to their own provider
        can [:read, :create, :update, :activate, :deactivate, :set_provider_role], User, :provider_id => user.provider_id
      
        # Provider admins can approve and decline trip claims associated with trip tickets that belong to their own provider, but not trip claims belonging to their own provider
        can [:approve, :decline], TripClaim, :trip_ticket => { :origin_provider_id => user.provider_id }

        # Provider admins can create, update, and destroy trip tickets belonging to their own provider
        can [:create, :update, :destroy], TripTicket, :origin_provider_id => user.provider_id
        
        # Provider admins can update, and destroy trip ticket comments associated with trip tickets belonging to their own provider
        can [:update], TripTicketComment, :trip_ticket => { :origin_provider_id => user.provider_id }
      end
      
      if user.has_any_role? [:scheduler, :provider_admin]        
        # Schedulers and provider admins can create trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets
        can :create, TripClaim, :claimant_provider_id => user.provider_id, :trip_ticket => { :origin_provider_id => ProviderRelationship.partner_ids_for_provider(user.provider) }

        # Schedulers and provider admins can update or rescind trip claims belonging to their own provider
        can [:update, :rescind], TripClaim, :claimant_provider_id => user.provider_id
        
        # Schedulers and provider admins can create trip ticket comments associated with trip tickets belonging to their own provider
        can :create, TripTicketComment, :trip_ticket => { :origin_provider_id => user.provider_id }
      end
    end

    # Users cannot deactivate themselves
    cannot :deactivate, User, :id => user.id
    
    # Users cannot destroy themselves
    cannot :destroy, User, :id => user.id
    
    # Nobody can delete trip ticket comments
    cannot :destroy, TripTicketComment

    # If you're trying to check `can? :read_multiple, @my_resources` where 
    # @my_resources is a collection of objects from an ActiveRecord::Relation
    # query, remember to use `@my_resources.all` instead to convert it to an 
    # Array otherwise this `can` definition won't be matched
    can :read_multiple, Array do |arr|
      arr.empty? || arr.inject(true){|r, el| r && can?(:read, el)}
    end
  end
end
