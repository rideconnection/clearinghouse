if Rails.env == 'development'
  namespace :test do
    desc "Run all tests (unit, functional, integration)."
    task :all do
      sh "rspec spec"
      sh "testdrb test/integration/**/*_test.rb"
    end
  end
end

