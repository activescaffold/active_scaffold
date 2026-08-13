require File.expand_path('boot', __dir__)

require 'rails/all'
require 'rails/test_unit/railtie'
require 'active_scaffold'

Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}".to_f

    config.filter_parameters += %i[password]
    config.action_mailer.default_url_options = { host: 'localhost:3000' }
    config.i18n.enforce_available_locales = false if config.i18n.respond_to?(:enforce_available_locales=)
    if config.active_record.respond_to?(:sqlite3) && config.active_record.sqlite3.respond_to?(:represent_boolean_as_integer=)
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
