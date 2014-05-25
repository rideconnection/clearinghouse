Devise::Async.setup do |config|
  config.enabled = !Rails.env.test? # && !Rails.env.development?
  config.backend = :delayed_job
  # config.queue   = :my_custom_queue
end
