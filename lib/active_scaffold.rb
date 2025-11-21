# frozen_string_literal: true

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

  def self.threadsafe!; end

  mattr_writer :jquery_ui_loaded, instance_writer: false
  def self.jquery_ui_included?
    return true if @@jquery_ui_loaded

    Jquery::Rails.const_defined?(:JQUERY_UI_VERSION) || Jquery.const_defined?(:Ui) if Object.const_defined?(:Jquery)
  end

  mattr_writer :js_config, instance_writer: false
  def self.js_config
    @@js_config ||= {scroll_on_close: :checkInViewport}
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
    File.expand_path '..', __dir__
  end

  def self.defaults(&)
    ActiveScaffold::Config::Core.configure(&)
  end

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('4.3', 'ActiveScaffold')
  end

  def self.log_exception(exception, message)
    line = exception.backtrace.find { |l| l.start_with? Rails.root.to_s }
    line ||= exception.backtrace.find { |l| l.start_with? ActiveScaffold.root }
    Rails.logger.error "#{exception.class.name}: #{exception.message} -- #{message}\n#{Rails.backtrace_cleaner.clean_frame(line) || line}"
  end
end
require 'active_scaffold/engine'
require 'ice_nine'
require 'ice_nine/core_ext/object'
require 'request_store'
require 'dartsass-sprockets'
