if Rails.env == 'development'

  ['test', 'test:all', 'test:functionals', 'test:integration', 'test:units'].each do |t|
    Rake::Task[t].clear if Rake::Task.task_defined?(t)
  end

  desc "Run all tests (unit, functional, integration) using Spork."
  task :test do
    sh 'find test -name "*_test.rb" -type f | xargs bundle exec testdrb'
  end

  namespace :test do
    desc "Run all tests (unit, functional, integration) using Spork."
    task :all do
      sh 'find test -name "*_test.rb" -type f | xargs bundle exec testdrb'
    end

    desc "Run tests in test/functional using Spork."
    task :functionals do
      sh 'find test/functional -name "*_test.rb" -type f | xargs bundle exec testdrb'
    end

    desc "Run tests in test/integration using Spork."
    task :integration do
      sh 'find test/integration -name "*_test.rb" -type f | xargs bundle exec testdrb'
    end

    desc "Run tests in test/unit using Spork."
    task :units do
      sh 'find test/unit -name "*_test.rb" -type f | xargs bundle exec testdrb'
    end
  end
end

