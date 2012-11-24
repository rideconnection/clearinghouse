class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :rememberable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  belongs_to :provider
  has_and_belongs_to_many :roles

  attr_accessible :active, :email, :name, :password, :password_confirmation,
    :phone, :roles, :role_ids, :title
    
  validate do |user|
    # Let Devise handle the length requirement.
    if user.password_required? && (user.password.blank? || !user.password.match(/\d/) || !user.password.match(/[\W_&&[^\s] ]/))
      user.errors[:password] << "have at least one number and at least one non-alphanumeric character"
    end
  end

  def has_role?(role_sym)
    roles.any? { |r| r.name.underscore.to_sym == role_sym }
  end

  def active_for_authentication?
    !!active
  end

  def inactive_message
    "Sorry, this account has been deactivated."
  end
end
