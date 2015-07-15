class User < ActiveRecord::Base
  devise :async, :database_authenticatable, :recoverable, :trackable, :validatable,
    :password_expirable, :password_archivable, :lockable, :session_limitable,
    :timeoutable, :confirmable

  belongs_to :provider, inverse_of: :users
  belongs_to :role
  has_many :filters
  has_many :bulk_operations

  validate do |user|
    # minimum 8 characters with at least one of each of the following: lower case alpha, upper case alpha, number, and non-alpha-numerical
    if user.password_required? && (
      user.password.blank?                    || # Cannot be empty
      !(8..20).include?(user.password.length) || # 8 - 20 characters
      !user.password.match(/[A-Z]/)           || # at least one lowercase letter
      !user.password.match(/[a-z]/)           || # at least one uppercase letter
      !user.password.match(/\d/)              || # at least one number
      !user.password.match(/[\W_&&[^\s] ]/)      # at least one non-alphanumeric character
    )
      user.errors[:password] << "does not meet complexity requirements. Passwords must be 8 to 20 characters in length with at least one of each of the following: lower case alpha, upper case alpha, number, and non-alpha-numerical"
    end
  end
  
  validates_presence_of :provider, :role

  default_scope ->{ order 'name ASC' }

  # All users, sorted by provider
  scope :all_by_provider, -> { joins("LEFT JOIN providers ON users.provider_id = providers.id").
    reorder('users.provider_id IS NULL DESC, providers.name ASC, users.name ASC') }

  def time_zone
    # TODO would be good to allow each user to set their time zone
    'Pacific Time (US & Canada)'
  end

  def partner_provider_ids_for_tickets
    [self.provider_id] + 
      ProviderRelationship.partner_ids_for_provider(self.provider)
  end

  def has_any_role?(role_syms)
    self.role.present? && role_syms.include?(self.role.name.underscore.to_sym)
  end
  
  def has_admin_role?
    self.role.is_admin_role?
  end

  def has_read_only_role?
    self.role.is_read_only_role?
  end

  def active_for_authentication?
    active?
  end

  def inactive_message
    "Sorry, this account has been deactivated."
  end

  def display_name
    if name.blank?
      email
    else
      name
    end
  end
  
  # Set the password without knowing the current password used in our
  # confirmation controller
  def attempt_set_password(params)
    p = {}
    p[:password] = params[:password]
    p[:password_confirmation] = params[:password_confirmation]
    update_attributes(p)
  end

  # Return whether a password has been set
  def has_no_password?
    self.encrypted_password.blank?
  end

  # Provide access to protected method pending_any_confirmation
  def only_if_unconfirmed
    pending_any_confirmation { yield }
  end
  
  # Override default password_required? method 
  def password_required?
    # Password is required if it is being set, but not for new records
    if !persisted?
      false
    else
      !password.nil? || !password_confirmation.nil?
    end
  end
end
