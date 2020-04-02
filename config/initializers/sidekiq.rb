# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/web'

redis_params = {
  url: 'redis://127.0.0.1:6379/0'
  # { url: 'redis://localhost:6379/0' }
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
