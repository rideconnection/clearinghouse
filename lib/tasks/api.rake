namespace :clearinghouse do
  namespace :api do
    namespace :nonces do
      desc 'Cleanup stale nonces more than 30 days old'
      task :cleanup => :environment do
        Nonce.cleanup
      end
    end
    
    desc 'Alias for nonces:cleanup'
    task :nonces => 'nonces:cleanup'
  end
end