namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app, :web), in: :sequence, wait: 5 do
      execute :mkdir, '-p', "#{ release_path }/tmp"
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end