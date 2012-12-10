class Ability
  include CanCan::Ability
 
  def initialize(user)
    user ||= User.new # guest user
 
    if user.has_role? :site_admin
      can :manage, :all
      can :set_provider, User
    elsif user.has_role? :provider_admin
      can :update, Provider do |provider|
        user.provider == provider
      end
      # TODO: Refactor
      can :create, User
      can :update, User do |u|
        user.provider and user.provider == u.provider
      end
      can :activate, User do |u|
        user.provider and user.provider == u.provider
      end
      can :deactivate, User do |u|
        user.provider and user.provider == u.provider
      end
      can :set_provider_role, User do |u|
        user.provider and user.provider == u.provider
      end
    end
    can :read, Provider
    can :read, User
    can :update, User do |u|
      user.id == u.id
    end
  end
end
