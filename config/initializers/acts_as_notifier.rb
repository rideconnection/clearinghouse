require 'acts_as_notifier'

ActsAsNotifier::Config.use_delayed_job = true
ActsAsNotifier::Config.default_mailer = 'NotificationMailer'