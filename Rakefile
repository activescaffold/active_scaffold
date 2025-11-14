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
begin
  load 'rails/perftest/railties/testing.tasks'
rescue LoadError => e # it's failing in Gitlab CI
  warn e.message
end

desc 'Test ActiveScaffold.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/performance/**/*')
  t.verbose = true
  t.warning = false
end

desc 'Generate documentation for ActiveScaffold.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = "ActiveScaffold #{ActiveScaffold::Version::STRING}"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task default: :test
