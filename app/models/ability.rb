class Ability
  include CanCan::Ability
 
  # Note: Latter ability rules override previous ones. See also:
  # https://github.com/ryanb/cancan/wiki/Ability-Precedence

  # Available roles: :site_admin, :provider_admin, :scheduler, :dispatcher, :read_only, :api
  
  # In block definitions with 3 arguments, the last argument is used by 
  # accessible_by to find resources, while the block is used to validate 
  # individual resources. See also:
  # https://github.com/ryanb/cancan/wiki/Defining-Abilities-with-Blocks
 
  def initialize(user)
    user ||= User.new # guest user
    
    if user.has_admin_role?
      
      can :manage, [User, Provider]
      
    end

    if user.has_any_role? [:site_admin, :provider_admin, :scheduler, :dispatcher, :api]
      
      # Per Feb 12, 2013 minutes: 
      #   Site Admin must be associated with a provider and can only act on
      #   tickets/claims/open capacity on behalf of his provider. If a site
      #   admin needs to do anything on behalf of another provider he/she will
      #   have to change his/her provider. (Only site admin can change his
      #   provider)

      # Dispatchers and above can edit/cancel open capacity belonging to their own provider
      # TODO - add a :cancel, :rescind, or similar action for open capacities
      can :update, OpenCapacity, :service => { :provider_id => user.provider_id }
      
      # Dispatchers and above can edit/cancel tickets belonging to their own provider
      can [:update, :rescind], TripTicket, :origin_provider_id => user.provider_id

      can [:create, :update], TripResult do |result| 
        result.can_be_edited_by?(user)
      end
    end
    
    if user.has_any_role? [:site_admin, :provider_admin, :scheduler, :api]
      
      # Per Feb 12, 2013 minutes: 
      #   Site Admin must be associated with a provider and can only act on
      #   tickets/claims/open capacity on behalf of his provider. If a site
      #   admin needs to do anything on behalf of another provider he/she will
      #   have to change his/her provider. (Only site admin can change his
      #   provider)

      # Schedulers and above can create trip tickets belonging to their own provider
      can :create, TripTicket, :origin_provider_id => user.provider_id
      
      # Schedulers and above can create, rescind, and update trip claims belonging to their own provider, on trip tickets belonging to providers they have an approved relationship with, but not their own provider's trip tickets
      can [:create, :rescind, :update], TripClaim, :claimant_provider_id => user.provider_id, :trip_ticket => { :origin_provider_id => user.partner_provider_ids_for_tickets - [user.provider_id] }

      # Schedulers and above can approve and decline trip claims belonging to trip tickets that belong to their own provider
      can [:approve, :decline], TripClaim, :trip_ticket => { :origin_provider_id => user.provider_id }

      # Schedulers and above can create open capacities belonging to their own provider
      can :create, OpenCapacity, :service => { :provider_id => user.provider_id }

      # Schedulers and above can create, rescind, and update service requests belonging to their own provider, on open capacities belonging to providers they have an approved relationship with, but not their own provider's trip tickets
      # TODO - add appropriate tests once service request functionality has been defined
      can [:create, :rescind, :update], ServiceRequest, :provider_id => user.provider_id, :open_capacity => { :service => { :provider_id => user.partner_provider_ids_for_tickets - [user.provider_id] } }

      # Schedulers and above can approve and decline service requests belonging to open capacities that belong to their own provider
      # TODO - add appropriate tests once service request functionality has been defined
      can [:approve, :decline], ServiceRequest, :open_capacity => { :service => { :provider_id => user.provider_id } }

      # Schedulers and above can manage (create, update, cancel) open capacity routes belonging to their own provider
      # TODO - add a :cancel, :rescind, or similar action for waypoints
      # TODO - add appropriate tests once waypoint functionality has been better defined
      can [:create, :read, :update], Waypoint, :open_capacity => { :service => { :provider_id => user.provider_id } }
              
    end

    if user.has_any_role? [:api]

      # per Clearinghouse User Ability Matrix doc, API has same abilities as Scheduler with these specific exceptions
      cannot :rescind, ServiceRequest

    end

    if user.has_any_role? [:site_admin, :provider_admin]
      
      # Per ticket #1225:
      #   Per the approved matrix site admins can:
      #     * set up partnerships
      #     * approve partnerships
      #     * end partnerships 
      #     * flag partner for as auto approve or unflag this.
      #   Site admins can do this for their own provider. To do this for 
      #   another provider they have to switch which provider he is 
      #   representing.
      
      # Provider admins and above can create provider relationships originating from their own provider
      can :create, ProviderRelationship, :requesting_provider_id => user.provider_id
      
      # Provider admins and above can update and destroy provider relationships that their own provider belongs to
      can [:update, :destroy], ProviderRelationship do |pr|
        pr.includes_user?(user)
      end
      
      # Provider admins and above can activate (aka approve) provider relationships sent to their own provider
      can :activate, ProviderRelationship, :cooperating_provider_id => user.provider_id
            
      # Provider admins and above can create, update and deactivate users belonging to their own provider
      can [:create, :update, :activate, :deactivate, :set_provider_role], User, :provider_id => user.provider_id
      
      # Provider admins and above can update and work with the keys of their own provider
      can [:update, :keys, :reset_keys], Provider, :id => user.provider_id

      # Provider admins and above can create and update services belonging to their own provider
      # TODO - add a :cancel, :rescind, or similar action for services
      can [:create, :update], Service, :provider_id => user.provider_id
              
      # Provider admins and above can update trip ticket comments associated with trip tickets belonging to their own provider
      can :update, TripTicketComment, :trip_ticket => { :origin_provider_id => user.provider_id }

      can :manage, EligibilityRequirement, :provider_id => user.provider_id
      can :manage, EligibilityRule, :eligibility_requirement => { :provider_id => user.provider_id }
      can :manage, MobilityAccommodation, :provider_id => user.provider_id
    end

    # All users can read open capacities that belonging to their own provider or providers they have an approved relationship with
    can :read, OpenCapacity, :service => { :provider_id => user.partner_provider_ids_for_tickets }

    # All users can read their own provider or providers they have an approved relationship with
    can :read, Provider, :id => user.partner_provider_ids_for_tickets

    # All users can read provider relationships that their own provider belongs to
    can :read, ProviderRelationship, ['? IN (cooperating_provider_id, requesting_provider_id)', user.provider_id] do |pr|
      pr.includes_user?(user)
    end

    # All users can read services belonging to their own provider or providers they have an approved relationship with
    can :read, Service, :provider_id => user.partner_provider_ids_for_tickets

    # All users can read services belonging to their own provider or providers they have an approved relationship with
    # TODO - add appropriate tests once service request functionality has been defined
    can :read, ServiceRequest, :open_capacity => { :service => { :provider_id => user.partner_provider_ids_for_tickets } }

    # All users can read trip ticket results and comments that belong to trip tickets that belong to their own provider or providers they have an approved relationship with
    # TODO - add appropriate tests once trip result functionality has been defined
    can :read, [TripResult, TripTicketComment], :trip_ticket => { :origin_provider_id => user.partner_provider_ids_for_tickets }

    # All users can read trip ticket claims that belong to their own provider or belong to trip tickets that belong to their own provider
    can :read, TripClaim, :claimant_provider_id => user.provider_id
    can :read, TripClaim, :trip_ticket => { :origin_provider_id => user.provider_id }

    # All users can read (search, filter, etc.) trip tickets belonging to their own provider or providers they have an approved relationship with,
    # except if there's a black list on the trip ticket
    can :read, TripTicket, ['origin_provider_id = ? OR (origin_provider_id IN (?) AND (ARRAY_LENGTH(provider_black_list, 1) IS NULL OR ? <> ALL(provider_black_list)) AND (ARRAY_LENGTH(provider_white_list, 1) IS NULL OR ? = ANY(provider_white_list)))', user.provider_id, user.partner_provider_ids_for_tickets, user.provider_id, user.provider_id] do |tt|
      tt.origin_provider_id == user.provider_id || (                                             # A user should always be able to see tickets belonging to their own provider
        user.partner_provider_ids_for_tickets.include?(tt.origin_provider_id) &&                 # If it's not their ticket, then is it from an approved provider?
        (tt.provider_black_list.blank? || !tt.provider_black_list.include?(user.provider_id)) && # If there's a blacklist, the user's provider MUST NOT be included
        (tt.provider_white_list.blank? || tt.provider_white_list.include?(user.provider_id))     # If there's a whitelist, the user's provider MUST be included
      )
    end
  
    # Per Feb 12, 2013 meeting minutes:
    #   If you can view a ticket you can comment on a ticket.
    can :create, TripTicketComment, :trip_ticket => { :origin_provider_id => user.partner_provider_ids_for_tickets }

    # All users can read users belonging to their own provider
    can :read, User, :provider_id => user.provider_id

    # All users can update their own profile
    can :update, User, :id => user.id

    # No user can deactivate themselves
    cannot :deactivate, User, :id => user.id

    # All users can manage their personal saved filters
    can :manage, Filter, :user_id => user.id
    
    # No user can destroy primary objects
    cannot :destroy, [
      OpenCapacity,
      Provider,
      Service,
      ServiceRequest,
      TripClaim,
      TripResult,
      TripTicket,
      TripTicketComment,
      User,
    ]
    
    # TODO - Verify destroy capabilities on remaining models
    #   FundingSource
    #   Location
    #   OperatingHours
    #   ProviderRelationship (Should we provide an option to deactivate a relationship rather than delete it?)
    #   Waypoint

    # If you're trying to check `can? :read_multiple, @my_resources` where 
    # @my_resources is a collection of objects from an ActiveRecord::Relation
    # query, remember to use `@my_resources.all` instead to convert it to an 
    # Array otherwise this `can` definition won't be matched
    can :read_multiple, Array do |arr|
      arr.empty? || arr.inject(true){|bool, resource| bool && can?(:read, resource)}
    end
  end
end
