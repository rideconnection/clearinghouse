if Rails.env == 'development'
  namespace :test do
    desc "Run all tests (unit, functional, integration)."
    task :all do
      sh 'rspec spec'
      sh 'find test -name "*_test.rb" -type f | xargs bundle exec testdrb'
    end
  end
end

