# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'active_scaffold/version'

Gem::Specification.new do |s|
  s.name = 'active_scaffold'
  s.version = ActiveScaffold::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = 'activescaffold@googlegroups.com'
  s.authors = ['Many, see README']
  s.homepage = 'https://github.com/activescaffold/active_scaffold'
  s.summary = 'Rails 4.x and 5.x versions of ActiveScaffold supporting prototype and jquery'
  s.description = 'Save time and headaches, and create a more easily maintainable set of pages, with ActiveScaffold. ' \
                  'ActiveScaffold handles all your CRUD (create, read, update, delete) user interface needs, ' \
                  'leaving you more time to focus on more challenging (and interesting!) problems.'
  s.require_paths = ['lib']
  s.files = `git ls-files {app,config/locales,lib,public,shoulda_macros,vendor}`.split("\n") + %w[LICENSE.md CHANGELOG.rdoc README.md]
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.license = 'MIT'

  s.required_ruby_version = '>= 3.2'

  s.add_dependency('dartsass-sprockets', '~> 3.2.0')
  s.add_dependency('ice_nine', '~> 0.11') # Deep Freeze Ruby Objects
  s.add_dependency('method_source', '~> 1.1')
  s.add_dependency('rails', '>= 7.2.0')
  s.add_dependency('request_store', '~> 1.3')
  s.metadata['rubygems_mfa_required'] = 'true'
end
