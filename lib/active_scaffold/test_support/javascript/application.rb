# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'logger'
require 'propshaft'
require 'propshaft/railtie'
require 'jquery-rails'
require 'active_scaffold'
require 'active_scaffold/engine'

module ActiveScaffold
  module TestSupport
    module Javascript
      class RailsApplication < Rails::Application
        config.root = File.expand_path('application', __dir__)
        config.eager_load = false
        config.enable_reloading = false
        config.consider_all_requests_local = true
        config.action_controller.allow_forgery_protection = false
        config.action_dispatch.show_exceptions = :none
        config.hosts.clear
        config.logger = Logger.new(nil)
        config.public_file_server.enabled = true
        config.secret_key_base = 'active-scaffold-plugin-javascript-tests'
      end

      module Application
        class << self
          def boot!
            application = Rails.application || RailsApplication.instance
            return application if application.initialized?

            application.initialize!
            application
          end
        end
      end
    end
  end
end
