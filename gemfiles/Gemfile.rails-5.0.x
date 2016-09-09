source 'https://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem 'activesupport', '>= 2.3.5'

gemspec :path => '../'
#gem 'active_scaffold', path: '../'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  # A static analysis security vulnerability scanner for Ruby on Rails applications
  gem 'brakeman', require: false
  gem 'rake'
  gem 'rdoc'
  gem 'rack'
end

group :development do
  gem 'localeapp'
end

group :test do
  gem 'shoulda', '>= 0'
  gem 'simplecov', '>= 0'
  gem 'mocha'
  gem 'rails', '~> 5.0.0'
  gem 'codeclimate-test-reporter', require: nil
  gem 'minitest-reporters', require:  nil
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jdbc-sqlite3'
  end

  platforms :ruby do
    gem 'sqlite3'
  end

  platforms :rbx do
    gem 'psych'
  end
end
