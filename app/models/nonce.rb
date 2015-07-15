class Nonce < ActiveRecord::Base
  belongs_to :provider
  
  # TODO - Add more validations - length, format, etc.
  validates :nonce, uniqueness: { scope: :provider_id }
  
  def self.cleanup
    Nonce.destroy_all(['created_at < ?', 30.days.ago])
  end
end
