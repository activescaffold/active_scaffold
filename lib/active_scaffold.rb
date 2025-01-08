module ActiveScaffold
  autoload :ActiveRecordPermissions, 'active_scaffold/active_record_permissions'
  autoload :AttributeParams, 'active_scaffold/attribute_params'
  autoload :Bridges, 'active_scaffold/bridges'
  autoload :Configurable, 'active_scaffold/configurable'
  autoload :ConnectionAdapters, 'active_scaffold/extensions/connection_adapter.rb'
  autoload :Constraints, 'active_scaffold/constraints'
  autoload :Core, 'active_scaffold/core'
  autoload :Finder, 'active_scaffold/finder'
  autoload :MarkedModel, 'active_scaffold/marked_model'
  autoload :OrmChecks, 'active_scaffold/orm_checks'
  autoload :Registry, 'active_scaffold/registry'
  autoload :RespondsToParent, 'active_scaffold/responds_to_parent'
  autoload :Routing, 'active_scaffold/extensions/routing_mapper'
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

  mattr_accessor :stylesheets, instance_writer: false
  self.stylesheets = []
  mattr_accessor :javascripts, instance_writer: false
  self.javascripts = []

  mattr_reader :threadsafe
  def self.threadsafe!
    @@threadsafe = true
  end

  def self.js_framework=(framework)
    warning = 'js_framework is deprecated as prototype support will be removed in 4.0'
    case framework
    when :jquery then
      warning +=
        if defined? Jquery
          ', it can be removed as it defaults to :jquery'
        else
          ", it's still needed in this version, as you are not using jquery-rails gem"
        end
    when :prototype then warning += ', convert your app to jQuery, and remove this call'
    end
    deprecator.warn warning
    @@js_framework = framework
  end

  def self.js_framework
    @@js_framework ||=
      if defined? Jquery
        :jquery
      elsif defined? PrototypeRails
        :prototype
      end
  end

  mattr_writer :jquery_ui_loaded, instance_writer: false
  def self.jquery_ui_included?
    return true if @@jquery_ui_loaded
    Jquery::Rails.const_defined?('JQUERY_UI_VERSION') || Jquery.const_defined?('Ui') if Object.const_defined?('Jquery')
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

  mattr_accessor :nested_subforms, instance_writer: false

  def self.root
    File.dirname(__FILE__) + '/..'
  end

  def self.defaults(&block)
    ActiveScaffold::Config::Core.configure(&block)
  end

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('4.0', 'ActiveScaffold')
  end
end
require 'active_scaffold/engine'
require 'ice_nine'
require 'ice_nine/core_ext/object'
require 'request_store'
