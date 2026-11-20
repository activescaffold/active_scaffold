# frozen_string_literal: true

SimpleCov.configure do
  # ActionView may compile a partial once per controller view class. One-shot
  # coverage keeps every executed ERB line instead of the last compilation's counts.
  enable_coverage :oneshot_line
  skip '/test/'
  skip '/lib/active_scaffold/version.rb'
  cover '{app,lib}/**/*.rb'
  cover %r{\Aapp/views/.*\.erb\z}
  cover_views 'app/views/**/*.erb'
end

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
]
