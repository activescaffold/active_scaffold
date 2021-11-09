module ActiveScaffold
  autoload :ActiveRecordPermissions, 'active_scaffold/active_record_permissions'
  autoload :AttributeParams, 'active_scaffold/attribute_params'
  autoload :Bridges, 'active_scaffold/bridges'
  autoload :Configurable, 'active_scaffold/configurable'
  autoload :Constraints, 'active_scaffold/constraints'
  autoload :Core, 'active_scaffold/core'
  autoload :DelayedSetup, 'active_scaffold/delayed_setup'
  autoload :Finder, 'active_scaffold/finder'
  autoload :MarkedModel, 'active_scaffold/marked_model'
  autoload :OrmChecks, 'active_scaffold/orm_checks'
  autoload :Registry, 'active_scaffold/registry'
  autoload :RespondsToParent, 'active_scaffold/responds_to_parent'
  autoload :Tableless, 'active_scaffold/tableless'
  autoload :Version, 'active_scaffold/version'

  def self.autoload_subdir(dir, mod = self, root = File.dirname(__FILE__))
    Dir["#{root}/active_scaffold/#{dir}/*.rb"].each do |file|
      basename = File.basename(file, '.rb')
      mod.module_eval do
        autoload basename.camelcase.to_sym, "active_scaffold/#{dir}/#{basename}"
      end
    end
  end

  module Actions
    ActiveScaffold.autoload_subdir('actions', self)
  end

  module Config
    ActiveScaffold.autoload_subdir('config', self)
  end

  module DataStructures
    ActiveScaffold.autoload_subdir('data_structures', self)
  end

  module Helpers
    ActiveScaffold.autoload_subdir('helpers', self)
  end

  class ControllerNotFound < RuntimeError; end
  class MalformedConstraint < RuntimeError; end
  class RecordNotAllowed < RuntimeError; end
  class ActionNotAllowed < RuntimeError; end
  class ReverseAssociationRequired < RuntimeError; end

  mattr_accessor :delayed_setup, instance_writer: false
  mattr_accessor :stylesheets, instance_writer: false
  self.stylesheets = []
  mattr_accessor :javascripts, instance_writer: false
  self.javascripts = []

  mattr_reader :threadsafe
  def self.threadsafe!
    @@threadsafe = true
  end

  mattr_writer :js_framework, instance_writer: false
  def self.js_framework
    @@js_framework ||=
      if defined? Jquery
        :jquery
      elsif defined? PrototypeRails
        :prototype
      end
  end

  mattr_writer :js_config, instance_writer: false
  def self.js_config
    @@js_config ||= {:scroll_on_close => :checkInViewport}
  end

  # exclude bridges you do not need, add to an initializer
  # name of bridge subdir should be used to exclude it
  # eg
  #   ActiveScaffold.exclude_bridges = [:cancan, :ancestry]
  mattr_writer :exclude_bridges, instance_writer: false
  def self.exclude_bridges
    @@exclude_bridges ||= []
  end

  def self.root
    File.dirname(__FILE__) + '/..'
  end

  def self.defaults(&block)
    ActiveScaffold::Config::Core.configure(&block)
  end
end
require 'active_scaffold/engine'
require 'ice_nine'
require 'ice_nine/core_ext/object'
require 'request_store'
# TODO: clean up extensions. some could be organized for autoloading, and others could be removed entirely.
Dir["#{File.dirname __FILE__}/active_scaffold/extensions/*.rb"].each { |file| require file }
