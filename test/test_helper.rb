$LOAD_PATH << "test"
require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] = "test"
  require File.expand_path('../../config/environment', __FILE__)

  require "database_cleaner"
  require "minitest/autorun"
  require "minitest/rails"
  require "minitest/rails/capybara"
  require "turn/autorun"

  class MiniTest::Rails::ActiveSupport::TestCase
    # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in
    # alphabetical order.
    #
    # Note: You'll currently still have to declare fixtures explicitly in
    # integration tests -- they do not yet inherit this setting
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end

  # Integration tests
  require "capybara/rails"

  module ActionController
    class IntegrationTest
      include Capybara::DSL
    end
  end

  # test descriptions including Clearinghouse::API will be handled as integration tests
  # so they can use the http methods get/post/put/delete
  MiniTest::Spec.register_spec_type(/Clearinghouse::API/, ActionDispatch::IntegrationTest)

  DatabaseCleaner.strategy = :deletion, {:except => %w[spatial_ref_sys]}
  MiniTest::Rails.override_testunit!
  Turn.config.format = :pretty
  Turn.config.trace = 30

  Dir[Rails.root.join("test/support/**/*.rb")].each {|f| require f}
end

Spork.each_run do
  DatabaseCleaner.clean
  FactoryGirl.reload
end
