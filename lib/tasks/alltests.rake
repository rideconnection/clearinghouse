if Rails.env == 'development'
  namespace :test do
    desc "Run all tests (unit, functional, integration)."
    task :all do
      sh "rspec spec"
      sh "SPORK_PORT=8989 testdrb -Itest/ test/integration/**/*_test.rb"
    end
  end
end

