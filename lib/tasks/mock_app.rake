# frozen_string_literal: true

namespace :mock_app do
  desc 'Start the mock_app server (default port 3000)'
  task :server do
    args = ARGV.drop_while { |a| a != '--' }.drop(1)
    Dir.chdir('test/mock_app') do
      exec({'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__)},
           'rails', 'server', *args)
    end
  end

  desc 'Start the mock_app console'
  task :console do
    args = ARGV.drop_while { |a| a != '--' }.drop(1)
    Dir.chdir('test/mock_app') do
      exec({'BUNDLE_GEMFILE' => File.expand_path('../../Gemfile', __dir__)},
           'rails', 'console', *args)
    end
  end
end
