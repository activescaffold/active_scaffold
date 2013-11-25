if RUBY_VERSION >= '1.9' && RUBY_ENGINE == 'ruby' # remove RUBY_ENGINE test when rubinius-coverage fix is released
  require 'simplecov'
  SimpleCov.start { add_filter 'test' }
end

ENV['RAILS_ENV'] = 'test'
require "mock_app/config/environment"
require 'rails/test_help'
require 'test/unit'

require 'mocha/setup'
begin
  require 'redgreen'
rescue LoadError
end

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

I18n.backend.store_translations :en, YAML.load_file(File.expand_path('../../config/locales/en.yml', __FILE__))["en"]

class Test::Unit::TestCase
  protected
  def config_for(klass, namespace = nil)
    ActiveScaffold::Config::Core.new("#{namespace}#{klass.to_s.underscore.downcase}")
  end
end
Object.send :remove_const, :Config
