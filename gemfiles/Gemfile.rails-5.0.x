source 'https://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem 'activesupport', '>= 2.3.5'

gemspec :path => '../'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  # A static analysis security vulnerability scanner for Ruby on Rails applications
  gem 'brakeman', require: false
  # A make-like build utility for Ruby
  gem 'rake'
  # RDoc produces HTML and command-line documentation for Ruby projects
  gem 'rdoc'
  # Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed
  gem 'bundler', '>= 1.0.0'
  # Rack provides a minimal interface between webservers that support Ruby and Ruby frameworks
  gem 'rack'
end

group :development do
  #  Send and retrieve your ruby i18n localizations to the Locale translation service https://www.localeapp.com
  gem 'localeapp'
end

group :test do
  # Makes tests easy on the fingers and the eyes
  gem 'shoulda', '>= 0'
  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites
  gem 'simplecov', '>= 0'
  # Mocking and stubbing library with JMock/SchMock syntax, which allows mocking and stubbing of methods on real (non-mock) classes
  gem 'mocha'
  # Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity.
  # It encourages beautiful code by favoring convention over configuration.
  gem 'rails', '~> 5.0.0'
  # Collects test coverage data from your Ruby test suite and sends it to Code Climate's hosted, automated code review service.
  # Based on SimpleCov
  gem 'codeclimate-test-reporter', require: nil
  # Create customizable MiniTest output formats
  gem 'minitest-reporters', require: nil

  platforms :jruby do
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'activerecord-jdbcsqlite3-adapter'
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'jdbc-sqlite3'
  end

  platforms :ruby do
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'sqlite3'
  end

  platforms :rbx do
    # A libyaml wrapper for Ruby
    gem 'psych'
  end
end
