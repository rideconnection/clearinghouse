# Required because we aren't using the default mounting point for DJW. See
# https://github.com/ejschmitt/delayed_job_web#serving-static-assets
namespace :deploy do
  namespace :assets do
    desc 'Link DelayedJobWeb assets folder'
    task :link_djw_assets do
      on roles(:app, :web), in: :sequence, wait: 5 do
        within release_path do
          with rails_env: fetch(:rails_env) do
            djw_path = capture :bundle, :show, "delayed_job_web"
            execute :ln, "-nFs", "#{djw_path}/lib/delayed_job_web/application/public", "public/job_queue"
          end
        end
      end
    end
  end
end
