require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'find'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test ActiveScaffold.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for ActiveScaffold.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActiveScaffold'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# Globals

PKG_NAME = 'active_scaffold_plugin'
PKG_VERSION = '3.2.2'

PKG_FILES = ['README', 'CHANGELOG', 'MIT-LICENSE', 'init.rb', 'install.rb']
PKG_DIRECTORIES = ['app/', 'lib/', 'public/', 'tasks/', 'test/']
PKG_DIRECTORIES.each do |dir|
  Find.find(dir) do |f|
    if FileTest.directory?(f) and f =~ /\.svn/
      Find.prune
    else
      PKG_FILES << f
    end
  end
end

# Tasks

task :package
Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
        p.need_tar = true
        p.package_files = PKG_FILES
end

# "Gem" part of the Rakefile
begin
        require 'rake/gempackagetask'

        spec = Gem::Specification.new do |s|
                s.platform = Gem::Platform::RUBY
                s.summary = "ActiveScaffold is a Rails plugin for rich ActiveRecord CRUD."
                s.name = PKG_NAME
                s.version = PKG_VERSION
                s.requirements << 'none'
                s.files = PKG_FILES
                s.description = "ActiveScaffold is a Rails plugin for rich ActiveRecord CRUD."
        end

        task :package_gem
        Rake::GemPackageTask.new(spec) do |pkg|
                pkg.need_zip = true
                pkg.need_tar = true
        end
rescue LoadError
end
