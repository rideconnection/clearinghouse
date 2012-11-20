class Ability
  include CanCan::Ability
 
  def initialize(user)
    user ||= User.new # guest user
 
    if user.has_role? :site_admin
      can :manage, :all
    elsif user.has_role? :provider_admin
      can :manage, Provider do |provider|
        user.provider == provider
      end
      can :manage, User do |u|
        user.provider and user.provider == u.provider or user.id == u.id
      end
    elsif user.has_role? :scheduler or user.has_role? :dispatcher
      can :manage, User do |u|
        user.id == u.id
      end
    end
  end
end
