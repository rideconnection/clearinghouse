# monkey patch ActsAsAudited to work with protected_attributes strict mode
# this won't be needed with strong parameters, see:
# https://github.com/collectiveidea/audited#using-attr_protected-or-strong_parameters

Audited::Adapters::ActiveRecord::Audit.class_eval do
  attr_accessible :action, :audited_changes, :comment, :associated
end
