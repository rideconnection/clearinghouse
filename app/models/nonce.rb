class Nonce < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :provider
  
  # attr_accessible :nonce, :provider_id
  
  # TODO - Add more validations - length, format, etc.
  validates :nonce, uniqueness: { scope: :provider_id }
  
  def self.cleanup
    Nonce.destroy_all(['created_at < ?', 30.days.ago])
  end
end
