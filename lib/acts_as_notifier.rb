# Allows an ActiveRecord model to tie notification emails to create and save callbacks with conditions
#
# Usage:
#   acts_as_notifier do
#     notify recipients, on_callback, options
#   end
#
# Params:
#   recipients  - can be a string containing email addresses, any object with an 'email' method, an array of
#                 strings/objects, or a proc or symbolic method name returning any of the above. procs will be
#                 passed the options hash as a parameter.
#
#   on_callback - :after_save or :after_create
#
#   options
#     :if       - string to eval, proc, or method name, !!result must equal true for notification to be sent. procs will
#                 be passed the options hash as a parameter.
#     :mailer   - a class inheriting from ActionMailer::Base, may be a string or symbol or actual class
#     :method   - mailer class method to invoke, should accept recipient list and sending ActiveRecord model as params
#     custom    - any additional options can be saved in the action and will be available to procs
#
# Examples:
#   acts_as_notifier do
#     notify proc { User.where(wants_alerts: true) }, :after_create, :if => proc { send_alert? }, :mailer => MyMailer, :method => :new_widget_alert
#     notify :owner, :after_save, :if => ->widget{ widget.broken? }, :mailer => MyMailer, :method => :broken_widget_alert
#   end
#
# Configuration:
#   ActsAsNotifier::Config.use_delayed_job = true/false
#   ActsAsNotifier::Config.default_mailer  = a class inheriting from ActionMailer::Base
#   ActsAsNotifier::Config.default_method  = mailer class method to invoke, should accept recipient list and sending
#                                            ActiveRecord model as params
#   ActsAsNotifier::Config.disabled        = true/false, can be globally enabled or disabled at any time

module ActsAsNotifier
  extend ActiveSupport::Concern

  module Config
    mattr_accessor :use_delayed_job, :default_mailer, :default_method, :disabled
  end

  module ClassMethods
    def acts_as_notifier(&block)
      cattr_accessor :notifier_actions
      self.notifier_actions = NotificationDsl.evaluate(&block).presence || []
      include LocalInstanceMethods
    end
  end

  module LocalInstanceMethods
    extend ActiveSupport::Concern

    included do
      after_create :notifier_create_handler
      after_save   :notifier_save_handler
      after_update :notifier_update_handler
    end

    # find a notification action matching options and trigger it, ignoring conditions
    def force_notification(options = {})
      opts = options.to_a
      action = self.class.notifier_actions.find { |action| action.to_a & opts == opts }
      notifier_send(action)
    end

    private

    def notifier_create_handler
      notifier_handler(:after_create) unless ActsAsNotifier::Config.disabled
    end

    def notifier_save_handler
      notifier_handler(:after_save) unless ActsAsNotifier::Config.disabled
    end

    def notifier_update_handler
      notifier_handler(:after_update) unless ActsAsNotifier::Config.disabled
    end

    def notifier_handler(callback_type)
      self.class.notifier_actions.each do |action|
        notifier_send(action) if action[:callback_type].to_sym == callback_type && notifier_conditions_satisfied?(action)
      end
    end

    def notifier_conditions_satisfied?(action)
      condition = action[:if]
      condition = case condition
        when String
          instance_eval(condition)
        when Proc
          instance_exec(action, &condition)
        when Symbol
          self.send(condition)
        else
          true
      end
      Rails.logger.debug "ActsAsNotifier condition not satisfied, skipping notification" if !condition
      !!condition
    end

    def notifier_recipients(action)
      recipients = action[:recipients]
      recipients = case recipients
        when Proc
          instance_exec(action, &recipients)
        when Symbol
          self.send(recipients)
        else
          recipients
      end
      recipients = [ recipients ] unless recipients.is_a?(Array)
      recipient_list = recipients.map {|r| r.respond_to?(:email) ? r.email : r }.join(', ')
      if recipient_list.blank?
        Rails.logger.debug "ActsAsNotifier recipients list is blank, notification will be skipped"
      else
        Rails.logger.debug "ActsAsNotifier recipients list \"#{ recipient_list }\""
      end
      recipient_list
    end

    def notifier_context(action)
      context = action[:context]
      context = case context
        when Proc
          instance_exec(action, &context)
        when Symbol
          self.send(context)
        else
          self
      end
    end

    def notifier_send(action)
      if (recipients = notifier_recipients(action)).present?
        mailer, method = notifier_get_mailer(action)
        context = notifier_context(action)
        if ActsAsNotifier::Config.use_delayed_job && mailer.respond_to?(:delay)
          Rails.logger.debug "ActsAsNotifier sending message with #{mailer.to_s}.delay.#{method}"
          mailer.delay.send(method, recipients, context)
        else
          Rails.logger.debug "ActsAsNotifier sending message with #{mailer.to_s}.#{method}"
          mailer.send(method, recipients, context).deliver_now
        end
      end
    end

    def notifier_get_mailer(action)
      mailer = action[:mailer] || ActsAsNotifier::Config.default_mailer
      raise "ActsAsNotifier invalid mailer configuration, mailer not specified" unless mailer.present?

      mailer = eval(mailer.to_s) if mailer.is_a?(String) || mailer.is_a?(Symbol)
      raise "ActsAsNotifier invalid mailer configuration, mailer must be a class that inherits ActionMailer::Base" unless mailer.is_a?(Class) && mailer <= ActionMailer::Base

      method = action[:method] || ActsAsNotifier::Config.default_method
      raise "ActsAsNotifier invalid mailer method configuration, method not specified" unless method.present?
      raise "ActsAsNotifier invalid mailer method configuration, method must be a string or symbol" unless method.is_a?(String) || method.is_a?(Symbol)
      raise "ActsAsNotifier invalid mailer method configuration, #{method} is not a valid class method of #{mailer.to_s}" unless mailer.respond_to?(method)
      return mailer, method
    end
  end

  class NotificationDsl
    attr_accessor :notification_actions

    class << self
      def evaluate(&script)
        self.new.tap {|inst| inst.instance_eval(&script)}.notification_actions
      end
    end

    def initialize
      @current_callback_type = nil
      @notification_actions = []
    end

    def after_create(&block)
      @current_callback_type = :after_create
      instance_eval(&block)
    end

    def after_save(&block)
      @current_callback_type = :after_save
      instance_eval(&block)
    end

    def after_update(&block)
      @current_callback_type = :after_update
      instance_eval(&block)
    end

    def notify(recipients, options = {})
      action = { recipients: recipients, callback_type: @current_callback_type }.merge(options || {})
      @notification_actions << action
    end
  end

end

ActiveRecord::Base.send(:include, ActsAsNotifier)
