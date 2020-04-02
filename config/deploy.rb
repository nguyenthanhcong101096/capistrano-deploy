# config valid only for current version of Capistrano
lock '3.6.1'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :airbrussh.
set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, false

# Default value for :linked_files is []
set :linked_files, ['config/database.yml', 'config/master.key', ".env.#{fetch(:stage)}"]

# Default value for linked_dirs is []
set :linked_dirs, ['log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'bundle', 'public/packs', 'config/puma', 'node_modules', 'public/uploads']

# Default value for keep_releases is 5
set :keep_releases, 3
set :local_user, 'congnt'
set :use_sudo, false

namespace :yarn do
  desc 'Run rake yarn install'
  task :install do
    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && yarn install")
      end
    end
  end
end

namespace :assets do
  desc 'Precompile assets locally and then rsync to deploy server'
  task :precompile do
    on roles(:all) do
      run_locally do
        execute "RAILS_ENV=#{fetch(:stage)} bundle exec rails assets:precompile"
        execute "rsync -av ./public/packs/ #{fetch(:user)}@#{fetch(:server)}:#{current_path}/public/packs/"
        execute 'rm -rf public/packs'
      end
    end
  end
end

namespace :deploy do
  desc 'Upload yml file.'
  task :upload_yml do
    on roles(:app) do
      execute "mkdir -p #{deploy_to}/current"
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/config/puma"
      upload!('package.json', "#{shared_path}/package.json")
      upload!("config/puma/#{fetch(:stage)}.rb", "#{shared_path}/config/puma/#{fetch(:stage)}.rb")
      upload!(".env.#{fetch(:stage)}", "#{shared_path}/.env.#{fetch(:stage)}")
      upload!('config/database.yml', "#{shared_path}/config/database.yml")
      upload!('config/master.key', "#{shared_path}/config/master.key")
    end
  end
end

namespace :db do
  desc 'Seed the database.'
  task :seed do
    on roles(:app) do
      within current_path do
        with(rails_env: fetch(:stage)) do
          execute :bundle, :exec, :rake, 'db:seed'
        end
      end
    end
  end

  desc 'Reset database'
  task :reset do
    on roles(:app) do
      within current_path do
        with(rails_env: fetch(:stage)) do
          execute :bundle, :exec, :rake, 'db:drop db:create db:migrate'
        end
      end
    end
  end
end

task :log do
  on roles(:app) do
    execute "cd #{shared_path}/log && tail -f #{fetch(:stage)}.log"
  end
end

before('deploy', 'puma:stop')

after('deploy:updated', 'assets:precompile')
