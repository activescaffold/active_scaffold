source 'https://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  # A static analysis security vulnerability scanner for Ruby on Rails applications
  gem 'brakeman', require: false
  gem 'rake'
  gem 'rdoc'
  gem 'bundler', '>= 1.0.0'
  gem 'localeapp'
  gem 'rack'
  platforms :rbx do
    gem 'rubysl'
    gem 'rubysl-openssl', '~> 2.1.0'
    gem 'rubysl-test-unit'
    gem 'racc'
  end
end

group :test do
  gem 'shoulda', '~> 2.11.3'
  gem 'simplecov', '>= 0'
  gem 'mocha'
  gem 'rails', '~> 3.2.22.2'
  gem 'minitest', '~> 4.7.0'
  gem 'minitest-rails'
  gem 'minitest-reporters', require: nil
  gem 'minitest_tu_shim'
  gem 'codeclimate-test-reporter', require: nil
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  platforms :ruby do
    gem 'sqlite3'
  end
end
