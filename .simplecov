# frozen_string_literal: true

if ENV['CI']
  SimpleCov.start do
    add_filter 'test'
    add_filter '/lib/active_scaffold/test_support/'
    track_files '{app,lib}/**/*.rb'
  end
end
