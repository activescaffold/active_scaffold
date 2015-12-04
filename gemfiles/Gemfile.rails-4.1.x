source 'https://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem 'activesupport', '>= 2.3.5'

gemspec :path => '../'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem 'rake'
  gem 'rdoc'
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
  gem 'simplecov', '>= 0'
  gem 'mocha'
  gem 'rails', '~> 4.1.1'
  gem 'codeclimate-test-reporter', require: nil
  gem 'minitest-reporters', require:  nil
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  platforms :ruby do
    gem 'sqlite3'
  end

  platforms :rbx do
    gem 'psych'
  end
end
