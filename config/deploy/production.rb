# frozen_string_literal: true

rbenv_ruby = File.read('.ruby-version').strip

set :stage, :production
set :server, '127.0.0.1'
set :user, 'app'

server '127.0.0.1', user: 'app', roles: %w[app web]

set :application, 'wakuwaku'
set :repo_url, 'git@github.com:nguyenthanhcong101096/capistrano_rails.git'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/var/www/project_app/public_html'

# capistrano-rails
set :rails_env, :production
set :migration_role, :web

set :assets_prefix, 'packs'
set :rails_assets_groups, :assets

set :normalize_asset_timestamps, ['public/packs']
set :keep_assets, 3

# capistrano-rbenv
set :rbenv_type, :user
set :rbenv_ruby, rbenv_ruby

# capistrano/bundler
set :bundle_binstubs, -> { shared_path.join('bin') }
set :bundle_path, -> { shared_path.join('bundle') }
set :bundle_without, %w[development test].join(' ')
set :bundle_jobs, 4
set :bundle_flags, '--deployment --quiet'

# capistrano/puma
set :puma_user, fetch(:user)
set :puma_conf, -> { "#{shared_path}/config/puma/staging.rb" }
set :puma_role, :web
set :puma_workers, 2

# capistrano/sidekiq
set :sidekiq_config, 'config/sidekiq.yml'

# Global options
# --------------
set :ssh_options, forward_agent: true
