require File.expand_path('../boot', __FILE__)

require "rails/all"
require "rails/test_unit/railtie"
require 'active_scaffold'

module RailsApp
  class Application < Rails::Application
    config.filter_parameters << :password
    config.action_mailer.default_url_options = { :host => "localhost:3000" }
  end
end
