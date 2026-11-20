# frozen_string_literal: true

require 'rake'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end
Bundler::GemHelper.install_tasks
require 'rake/testtask'
require 'rdoc/task'

INSTALLED_BRIDGE_TESTS = 'test/bridges/installed/**/*_test.rb'

begin
  load 'rails/perftest/railties/testing.tasks'
rescue LoadError => e # it's failing in Gitlab CI
  warn e.message
end

desc 'Test ActiveScaffold.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.test_files =
    FileList['test/**/*_test.rb']
      .exclude('test/performance/**/*')
      .exclude(INSTALLED_BRIDGE_TESTS)
  t.verbose = true
  t.warning = false
end

Rake::Task[:test].enhance(['mock_app:assets'])

namespace :test do
  desc 'Test bridges against their installed gems.'
  task :installed_bridges do # rubocop:disable Rails/RakeEnvironment -- each test boots an isolated environment
    expected_gemfile = File.expand_path('gemfiles/Gemfile.bridges', __dir__)
    current_gemfile = File.expand_path(Bundler.default_gemfile.to_s)
    abort "Run with BUNDLE_GEMFILE=#{expected_gemfile}" unless current_gemfile == expected_gemfile

    installed_bridge_tests = FileList[INSTALLED_BRIDGE_TESTS]
    abort "No installed bridge tests found in #{INSTALLED_BRIDGE_TESTS}" if installed_bridge_tests.empty?

    installed_bridge_tests.each { |test_file| ruby '-Ilib:test', test_file }
  end # rubocop:enable Rails/RakeEnvironment
end

desc 'Generate documentation for ActiveScaffold.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = "ActiveScaffold #{ActiveScaffold::Version::STRING}"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Dir.glob('lib/tasks/*.rake').each { |r| import r }

task default: :test
