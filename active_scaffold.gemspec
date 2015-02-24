# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'active_scaffold/version'

Gem::Specification.new do |s|
  s.name = 'active_scaffold'
  s.version = ActiveScaffold::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = 'activescaffold@googlegroups.com'
  s.authors = ['Many, see README']
  s.homepage = 'http://activescaffold.com'
  s.summary = 'Rails 3.2 and 4.0 version of activescaffold supporting prototype and jquery'
  s.description = 'Save time and headaches, and create a more easily maintainable set of pages, with ActiveScaffold. ActiveScaffold handles all your CRUD (create, read, update, delete) user interface needs, leaving you more time to focus on more challenging (and interesting!) problems.'
  s.require_paths = ['lib']
  s.files = `git ls-files {app,config,lib,public,shoulda_macros,vendor}`.split("\n") + %w[MIT-LICENSE CHANGELOG README.md]
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.licenses = ['MIT']
  s.test_files = `git ls-files test`.split("\n")

  s.required_ruby_version = '>= 1.9'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=

  s.add_development_dependency('shoulda', ['>= 0'])
  s.add_development_dependency('bundler', ['~> 1.0'])
  # s.add_runtime_dependency(%q<render_component_vho>, [">= 0"])
  s.add_runtime_dependency('rails', '>= 3.2.18', '<5')
  # Automatic Ruby code style checking tool. Aims to enforce the community-driven Ruby Style Guide
  s.add_development_dependency 'rubocop'
end

