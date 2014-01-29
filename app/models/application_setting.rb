# These settings are stored in the `settings` table in the
# database, but are also cached in tmp/cache. You can destroy
# them all using `ApplicationSetting.delete_all`, but you'll
# also want to `rake tmp:clear` to get rid of the cached values
class ApplicationSetting < RailsSettings::CachedSettings
	attr_accessible :var
  
  def self.update_settings(params)
    transaction do
      self['devise.maximum_attempts']         = params['devise.maximum_attempts'].to_i           if params.has_key? "devise.maximum_attempts"
      self['devise.password_archiving_count'] = params['devise.password_archiving_count'].to_i   if params.has_key? "devise.password_archiving_count"
      self['devise.expire_password_after']    = params['devise.expire_password_after'].to_i.days if params.has_key? "devise.expire_password_after"
      if params.has_key? "devise.timeout_in"
        timeout_in = params['devise.timeout_in'].to_i
        # a nil value means timeoutable is disabled
        self['devise.timeout_in'] = (timeout_in == 0) ? nil : timeout_in.minutes
      end
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
