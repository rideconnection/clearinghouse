class User < ActiveRecord::Base
  devise :async, :database_authenticatable, :recoverable, :trackable, :validatable,
    :password_expirable, :password_archivable, :lockable, :session_limitable,
    :timeoutable

  belongs_to :provider, inverse_of: :users
  belongs_to :role
  has_many :filters
  has_many :bulk_operations

  attr_accessible :active, :email, :name, :password, :password_confirmation,
    :must_generate_password, :phone, :provider_id, :role_id, 
    :title, :notification_preferences, :failed_attempts, :locked_at

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

  before_validation :generate_a_password, :on => :create

  default_scope ->{ order 'name ASC' }

  # All users, sorted by provider
  scope :all_by_provider, ->{ joins("LEFT JOIN providers ON users.provider_id = providers.id").
    reorder('users.provider_id IS NULL DESC, providers.name ASC, users.name ASC') }

  # Temporary attribute for auto-generated password tokens
  attr_accessor :must_generate_password

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
    !!active
  end

  def inactive_message
    "Sorry, this account has been deactivated."
  end

  def need_to_generate_password?
    !!must_generate_password
  end
  
  def display_name
    if name.blank?
      email
    else
      name
    end
  end
  
  private

  def generate_a_password
    if need_to_generate_password?
      temp_token = (Devise.friendly_token.first(16) +
        Array("a".."z").shuffle.first +
        Array("A".."Z").shuffle.first +
        Array("0".."9").shuffle.first +
        "!@\#$%^&*".split("").shuffle.first).split("").shuffle.join("")
      self.password = self.password_confirmation = temp_token
      raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
      self.reset_password_token = hashed_token
      self.reset_password_sent_at = Time.zone.now
    end
  end
end
