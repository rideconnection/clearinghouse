namespace :rails do
  desc "Open the rails console on the remote app server"
  task :console => 'rvm:hook' do
    on roles(:app), :primary => true do |host|
      execute_interactively host, "console #{fetch(:stage)}"  
    end
  end
 
  desc "Open the rails dbconsole on each of the remote servers"
  task :dbconsole => 'rvm:hook' do
    on roles(:app), :primary => true do |host|
      execute_interactively host, "dbconsole #{fetch(:stage)}"  
    end
  end
 
  def execute_interactively(host, command)
    command = "cd #{fetch(:deploy_to)}/current && #{SSHKit.config.command_map[:bundle]} exec rails #{command}"
    puts command if fetch(:log_level) == :debug
    exec "ssh -l #{host.user} #{host.hostname} -p #{host.port || 22} -t '#{command}'"
  end
end
