# frozen_string_literal: true

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov_json_formatter'
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ]
end

ENV['RAILS_ENV'] = 'test'
require 'mock_app/config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'mocha/minitest'

require 'minitest/reporters'
Minitest::Reporters.use! unless ENV['RM_INFO']

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load Rails.root.join('db/schema.rb')
  $stdout = stdout
end
load_schema

# avoid freezing defaults so we can stubs in tests for testing with different defaults
class << ActiveScaffold::Config::Core
  def freeze; end
end

%w[model_stub const_mocker company].each do |file|
  require File.join(File.dirname(__FILE__), file)
end

I18n.backend.store_translations :en, YAML.load_file(File.expand_path('../config/locales/en.yml', __dir__))['en']

Minitest::Test.class_eval do
  protected

  def config_for(klass, namespace = nil)
    ActiveScaffold::Config::Core.new("#{namespace}#{klass.to_s.underscore.downcase}")
  end
end

Config = RbConfig # HACK: needed some comments

class ColumnMock < ActiveScaffold::Tableless::Column
end
