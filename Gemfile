source 'https://rubygems.org'

gemspec

group :development do
  #  Send and retrieve your ruby i18n localizations to the Locale translation service https://www.localeapp.com
  gem 'localeapp'
  # RDoc produces HTML and command-line documentation for Ruby projects
  gem 'rdoc'
end

group :performance do
  gem 'rails-perftest', github: 'letsevents/rails-perftest'
  platforms :ruby do
    gem 'ruby-prof'
  end
end

group :development, :lint do
  # A static analysis security vulnerability scanner for Ruby on Rails applications
  gem 'brakeman', require: false
  # Patch-level verification for Bundler
  gem 'bundler-audit', require: false
  # A Ruby static code analyzer. Aims to enforce the community-driven Ruby Style Guide
  gem 'rubocop', '0.52.1', require: false
end

group :development, :lint, :test do
  # Manage translation and localization with static analysis, for Ruby i18n
  gem 'i18n-tasks', require: false
  gem 'rake', require: false
end

group :development, :test do
  # Rack provides a minimal interface between webservers that support Ruby and Ruby frameworks
  gem 'rack'
end

group :test do
  # Makes tests easy on the fingers and the eyes
  gem 'shoulda'
  # Mocking and stubbing library with JMock/SchMock syntax, which allows mocking and stubbing of methods on real (non-mock) classes
  gem 'mocha'
  # Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity.
  # It encourages beautiful code by favoring convention over configuration.
  gem 'rails', '~> 6.0.0'
  # Create customizable MiniTest output formats
  gem 'minitest-reporters', require: false
  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites
  gem 'simplecov', require: false

  platforms :jruby do
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'activerecord-jdbcsqlite3-adapter'
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'jdbc-sqlite3'
  end

  platforms :ruby do
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'sqlite3', '~> 1.4.0'
  end
end
