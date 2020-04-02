#!/usr/bin/env puma

app_path = '/var/www/project_app/public_html'

directory "#{app_path}/current"

rackup "#{app_path}/current/config.ru"

environment 'staging'

daemonize true

pidfile "#{app_path}/shared/tmp/pids/puma.pid"

state_path "#{app_path}/shared/tmp/pids/puma.state"

stdout_redirect "#{app_path}/shared/log/stdout", "#{app_path}/shared/log/stderr", true

threads 5, ENV.fetch('RAILS_MAX_THREADS') { 5 }

bind "unix://#{app_path}/shared/tmp/sockets/puma.sock"

on_restart do
  ENV['BUNDLE_GEMFILE'] = "#{app_path}/current/Gemfile"
end

workers ENV['WEB_CONCURRENCY'].to_i

on_worker_boot do
  defined?(ActionRecord::Base) && ActionRecord::Base.establish_connection
end

preload_app!

tag 'project_app'

worker_timeout 30

worker_boot_timeout 30

activate_control_app "unix://#{app_path}/shared/tmp/sockets/pumactl.sock"

