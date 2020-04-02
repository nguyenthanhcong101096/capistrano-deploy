# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'

redis_params = {
  # url: ENV['REDIS_URL_SIDEKIQ']
  url: 'redis://localhost:6379/0'
}

# Stats:
# concurrency: sidekiq client does not need concurrency options
# size: 5 - default
Sidekiq.configure_client do |config|
  config.redis = redis_params
end

# Stats:
# concurrency: 5
# size: 10 ( concurrency + 5 )
Sidekiq.configure_server do |config|
  config.redis = redis_params
end
