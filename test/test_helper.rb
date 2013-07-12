ENV['RAILS_ENV'] = 'test'
$:.unshift File.dirname(__FILE__)
require "mock_app/config/environment"
require 'rails/test_help'
require 'active_scaffold'

require 'mocha/setup'
begin
  require 'redgreen'
rescue LoadError
end

def load_schema
  stdout = $stdout
  $stdout = StringIO.new # suppress output while building the schema
  load File.join(ENV['RAILS_ROOT'], 'db', 'schema.rb')
  $stdout = stdout
end

def silence_stderr(&block)
  stderr = $stderr
  $stderr = StringIO.new
  yield
  $stderr = stderr
end

for file in %w[model_stub const_mocker]
  require File.join(File.dirname(__FILE__), file)
end

class Test::Unit::TestCase
  protected
  def config_for(klass, namespace = nil)
    ActiveScaffold::Config::Core.new("#{namespace}#{klass.to_s.underscore.downcase}")
  end
end
