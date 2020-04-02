# frozen_string_literal: true

Rails.application.config.active_job.queue_adapter = %w[development test].include?(Rails.env) ? :async : :sidekiq
