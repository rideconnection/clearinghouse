class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :rememberable,
  # :registerable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :trackable, :validatable

  belongs_to :provider
  belongs_to :role

  attr_accessible :active, :email, :name, :password, :password_confirmation,
    :must_generate_password, :phone, :provider_id, :role_id, 
    :title

  validate do |user|
    # This pattern should technically work, but it doesn't...
    # validates_format_of :password, :if => :password_required?,
    #                     :with => /^(?=.*[0-9])(?=.*[\W_&&[^\s] ])[\w\W&&[^\s] ]{6,20}$/i, # Regexp tested at http://www.rubular.com/r/7peotZQNui
    #                     :message => "must be 6 to 20 characters in length and have at least one number and one non-alphanumeric character"
    # So...                    
    if user.password_required? && (user.password.blank? || !(6..20).include?(user.password.length) || !user.password.match(/\d/) || !user.password.match(/[\W_&&[^\s] ]/))
      user.errors[:password] << "must be 6 to 20 characters in length and have at least one number and one non-alphanumeric character"
    end
  end
  
  validates_presence_of :provider, :role

  before_validation :generate_a_password, :on => :create

  default_scope order('name ASC')

  # All users, sorted by provider
  scope :all_by_provider, joins("LEFT JOIN providers ON users.provider_id = providers.id").
    reorder('users.provider_id IS NULL DESC, providers.name ASC, users.name ASC')

  # Temporary attribute for auto-generated password tokens
  attr_accessor :must_generate_password 

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
      temp_token = Devise.friendly_token.first(10) + "!1"
      self.password = self.password_confirmation = temp_token
      self.reset_password_token = User.reset_password_token
      self.reset_password_sent_at = Time.now
    end
  end
end
