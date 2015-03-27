require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'rails/test_unit/railtie'
require 'active_scaffold'

module RailsApp
  class Application < Rails::Application
    config.filter_parameters << :password
    config.action_mailer.default_url_options = {:host => 'localhost:3000'}
    config.i18n.enforce_available_locales = false if config.i18n.respond_to? :enforce_available_locales
  end
end
