class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :rememberable,
  # :registerable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  belongs_to :provider
  has_and_belongs_to_many :roles

  attr_accessible :active, :email, :name, :password, :password_confirmation,
    :phone, :provider, :provider_id, :roles, :role_ids, :title
    
  # This pattern should technically work, but it doesn't...
  # validates_format_of :password, :if => :password_required?,
  #                     :with => /^(?=.*[0-9])(?=.*[\W_&&[^\s] ])[\w\W&&[^\s] ]{6,20}$/i, # Regexp tested at http://www.rubular.com/r/7peotZQNui
  #                     :message => "must be 6 to 20 characters in length and have at least one number and one non-alphanumeric character"
  # So...                    
  validate do |user|
    if user.password_required? && (user.password.blank? || !(6..20).include?(user.password.length) || !user.password.match(/\d/) || !user.password.match(/[\W_&&[^\s] ]/))
      user.errors[:password] << "must be 6 to 20 characters in length and have at least one number and one non-alphanumeric character"
    end
  end

  default_scope order('name ASC')

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
