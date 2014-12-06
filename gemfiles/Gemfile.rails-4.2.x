source "https://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development, :test do
  gem "rake"
  gem "rdoc"
  gem "bundler", ">= 1.0.0"
  gem "localeapp"
  platforms :rbx do
    gem "rubysl"
    gem "rubysl-test-unit"
    gem "racc"
  end
end

group :test do
  gem "shoulda", ">= 0"
  gem "simplecov", ">= 0"
  gem "mocha"
  gem "rails", :github => 'rails/rails', :branch => '4-2-stable'
  gem "arel", :github => 'rails/arel'
  gem "rack", :github => 'rack/rack'
  gem "i18n", :github => 'svenfuchs/i18n'
  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
  end

  platforms :ruby do
    gem "sqlite3"
  end
end
