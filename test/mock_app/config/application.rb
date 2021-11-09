require File.expand_path('boot', __dir__)

require 'rails/all'
require 'rails/test_unit/railtie'
require 'active_scaffold'

module RailsApp
  class Application < Rails::Application
    config.filter_parameters << :password
    config.action_mailer.default_url_options = {:host => 'localhost:3000'}
    config.i18n.enforce_available_locales = false if config.i18n.respond_to? :enforce_available_locales
    config.active_record.sqlite3.represent_boolean_as_integer = true if config.active_record.sqlite3.respond_to? :represent_boolean_as_integer
  end
end
