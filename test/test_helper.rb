require 'simplecov'
SimpleCov.start { add_filter 'test' }

ENV['RAILS_ENV'] = 'test'
require 'mock_app/config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'mocha/setup'

require 'minitest/reporters'
Minitest::Reporters.use!

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load File.join(Rails.root, 'db', 'schema.rb')
  $stdout = stdout
end
load_schema

for file in %w[model_stub const_mocker company]
  require File.join(File.dirname(__FILE__), file)
end

I18n.backend.store_translations :en, YAML.load_file(File.expand_path('../../config/locales/en.yml', __FILE__))['en']

unless defined? Minitest::Test
  class Minitest::Test < MiniTest::Unit::TestCase
  end
end

class MiniTest::Test
  protected

  def config_for(klass, namespace = nil)
    ActiveScaffold::Config::Core.new("#{namespace}#{klass.to_s.underscore.downcase}")
  end
end

Object.send :remove_const, :Config
class ColumnMock < ActiveScaffold::Tableless::Column; end
