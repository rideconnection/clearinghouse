#$LOAD_PATH << "test"
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
#require "database_cleaner"
require "minitest/autorun"
require "minitest/rails"
require "minitest/rails/capybara"
require "minitest/pride"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  # Add more helper methods to be used by all tests here...
end

# Integration tests
require "capybara/rails"

module ActionDispatch
  class IntegrationTest
    include Capybara::DSL

    # the way our test suite is set up, we need to manually clear Capybara sessions
    def teardown
      Capybara.reset_sessions!
      Capybara.use_default_driver
    end
  end
end

# test descriptions including Clearinghouse::API will be handled as integration tests
# so they can use the http methods get/post/put/delete
MiniTest::Spec.register_spec_type(/Clearinghouse::API/, ActionDispatch::IntegrationTest)

#DatabaseCleaner.strategy = :deletion, {:except => %w[spatial_ref_sys]}

# by default, do not send email notifications in test mode
ActsAsNotifier::Config.disabled = true

Devise::Async.enabled = false

Dir[Rails.root.join("test/support/*.rb")].each {|f| require f}

# setup do
#   DatabaseCleaner.clean
#   FactoryGirl.reload
#
#   ApplicationSetting.update_settings ApplicationSetting.defaults
#   ApplicationSetting.apply!
# end
