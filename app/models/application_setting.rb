class ApplicationSetting < RailsSettings::CachedSettings
	attr_accessible :var
  
  def self.update_settings(params)
    transaction do
      self['devise.maximum_attempts']         = params['devise.maximum_attempts'].to_i           if params.has_key? "devise.maximum_attempts"
      self['devise.password_archiving_count'] = params['devise.password_archiving_count'].to_i   if params.has_key? "devise.password_archiving_count"
      self['devise.expire_password_after']    = params['devise.expire_password_after'].to_i.days if params.has_key? "devise.expire_password_after"
      self['devise.timeout_in']               = params['devise.timeout_in'].to_i.minutes         if params.has_key? "devise.timeout_in"
    end
  end
  
  def self.apply!
    Devise.expire_password_after    = self['devise.expire_password_after']
    Devise.maximum_attempts         = self['devise.maximum_attempts']
    Devise.password_archiving_count = self['devise.password_archiving_count']
    Devise.timeout_in               = self['devise.timeout_in']
    return true
  end
end
