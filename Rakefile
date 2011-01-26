require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'find'

require 'jeweler'
require './lib/active_scaffold/version.rb'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "active_scaffold_vho"
  gem.version = ActiveScaffold::Version::STRING
  gem.homepage = "http://github.com/vhochstein/active_scaffold"
  gem.license = "MIT"
  gem.summary = %Q{Rails 3 Version of activescaffold supporting prototype and jquery}
  gem.description = %Q{Save time and headaches, and create a more easily maintainable set of pages, with ActiveScaffold. ActiveScaffold handles all your CRUD (create, read, update, delete) user interface needs, leaving you more time to focus on more challenging (and interesting!) problems.}
  gem.email = "activescaffold@googlegroups.com"
  gem.authors = ["Many, see README"]
  gem.add_runtime_dependency 'render_component_vho'
  gem.add_runtime_dependency 'verification'
  gem.add_runtime_dependency 'rails', '~> 3.0.0'
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

desc 'Test ActiveScaffold.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for ActiveScaffold.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActiveScaffold #{ActiveScaffold::Version::STRING}'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end