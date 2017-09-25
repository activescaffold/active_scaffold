$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'active_scaffold/version'

Gem::Specification.new do |s|
  s.name = 'active_scaffold'
  s.version = ActiveScaffold::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = 'activescaffold@googlegroups.com'
  s.authors = ['Many, see README']
  s.homepage = 'https://github.com/activescaffold/active_scaffold'
  s.summary = 'Rails 4.x and 5.x versions of ActiveScaffold supporting prototype and jquery'
  s.description = 'Save time and headaches, and create a more easily maintainable set of pages, with ActiveScaffold. ActiveScaffold handles all your CRUD (create, read, update, delete) user interface needs, leaving you more time to focus on more challenging (and interesting!) problems.'
  s.require_paths = ['lib']
  s.files = `git ls-files {app,config,lib,public,shoulda_macros,vendor}`.split("\n") + %w[LICENSE CHANGELOG README.md]
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.license = 'MIT'
  s.test_files = `git ls-files test`.split("\n")

  s.required_ruby_version = '>= 2.0'

  # Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity.
  # It encourages beautiful code by favoring convention over configuration.
  s.add_runtime_dependency('rails', '>= 4.0.5')
  # Deep Freeze Ruby Objects
  s.add_runtime_dependency('ice_nine', '~> 0.11')
end
