source 'https://rubygems.org'

gemspec path: '../'

group :development, :lint, :test do
  gem 'rake', require: false
end

group :development, :test do
  # Rack provides a minimal interface between webservers that support Ruby and Ruby frameworks
  gem 'rack'
  gem 'propshaft'
  gem 'dartsass-rails'
  gem 'jquery-rails'
  gem 'puma'
end

group :test do
  # Browser support for the reusable plugin JavaScript test application.
  gem 'capybara'
  # Mocking and stubbing library with JMock/SchMock syntax, which allows mocking and stubbing of methods on real (non-mock) classes
  gem 'mocha'
  # Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity.
  # It encourages beautiful code by favoring convention over configuration.
  gem 'rails', '~> 8.1.0'
  # Create customizable MiniTest output formats
  gem 'minitest-reporters', require: false
  # Association compatibility tests use reflection metadata only; no MongoDB server is required.
  gem 'mongoid', '~> 9.1', require: false
  gem 'selenium-webdriver', '< 4.45'
  # Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites
  gem 'simplecov', '~> 1.3.0', require: false

  platforms :jruby do
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'activerecord-jdbcsqlite3-adapter', github: 'jruby/activerecord-jdbc-adapter', branch: 'master'
    gem 'activerecord-jdbc-adapter', github: 'jruby/activerecord-jdbc-adapter', branch: 'master'
    # This module allows Ruby programs to interface with the SQLite3 database engine
    gem 'jdbc-sqlite3'
  end

  # This module allows Ruby programs to interface with the SQLite3 database engine
  gem 'sqlite3', platform: :mri
end
