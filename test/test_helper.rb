require 'simplecov' if RUBY_ENGINE == 'ruby'

ENV['RAILS_ENV'] = 'test'
require 'mock_app/config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'mocha/setup'
require 'cow_proxy'

require 'minitest/reporters'
Minitest::Reporters.use!

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load Rails.root.join('db', 'schema.rb')
  $stdout = stdout
end
load_schema

ActiveScaffold.threadsafe!
# avoid freezing defaults so we can stubs in tests for testing with different defaults
ActiveScaffold::Config::Core.stubs(:freeze)

%w[model_stub const_mocker company].each do |file|
  require File.join(File.dirname(__FILE__), file)
end

I18n.backend.store_translations :en, YAML.load_file(File.expand_path('../config/locales/en.yml', __dir__))['en']

# rails 4.0
unless defined? Minitest::Test
  class Minitest::Test < MiniTest::Unit::TestCase
  end

  class MiniTest::Unit::TestCase
    def with_js_framework(framework)
      framework, ActiveScaffold.js_framework = ActiveScaffold.js_framework, framework
      yield
      ActiveScaffold.js_framework = framework
    end
  end
end

class MiniTest::Test
  protected

  def with_js_framework(framework)
    framework, ActiveScaffold.js_framework = ActiveScaffold.js_framework, framework
    yield
    ActiveScaffold.js_framework = framework
  end

  def config_for(klass, namespace = nil)
    ActiveScaffold::Config::Core.new("#{namespace}#{klass.to_s.underscore.downcase}")
  end
end

Config = RbConfig # HACK: needed some comments

class ColumnMock < ActiveScaffold::Tableless::Column; end
