# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Clearinghouse::Application.initialize!

Clearinghouse::Application.configure do
  config.action_mailer.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => 587,
    :domain               => 'rideconnection.org',
    :user_name            => 'panopticdev',
    :password             => 'panopticpilot2299',
    :authentication       => 'plain',
    :enable_starttls_auto => true 
  }
end
