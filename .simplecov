# frozen_string_literal: true

SimpleCov.configure do
  skip '/test/'
  skip '/lib/active_scaffold/test_support/'
  cover '{app,lib}/**/*.rb'
  cover %r{\Aapp/views/.*\.erb\z}
  cover_views 'app/views/**/*.erb'
end

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
]
