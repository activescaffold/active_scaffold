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

  # A way to define the tags and html attributes used in different places.
  # Changing the class or replacing the attributes may break the default AS stylesheets, but not JS or functionality.
  #
  # The keys in the hash are the names used by ActiveScaffold to identify the
  # elements.
  # The values are a hash of attributes used to create the markup, supporting the following keys:
  # * The :tag key can be used to specify a different tag name for the element.
  # * The :attributes key can be used to specify additional html attributes.
  # * The :proc key can be used to specify a method to dinamically return the tag and attributes hash, as an array.
  #   When :proc is present, :tag and :attributes won't be used. The proc will receive an options hash, which usually
  #   will be a hash with html attributes, but in some cases may have other options:
  #   * For :action_link_group the hash will have keys such as :level, :first_action, and other options supported by
  #     +display_action_links+
  #   * For :action_link_separator the hash will have keys such as :level, :level_0_tag, and other options supported by
  #     +display_action_links+
  # Some keys don't have a :tag key, because only attributes are used, the tag is hardcoded, usually elements that are
  # rendered as a form or table, or a table's element (thead, tbody, tr, td, th, tfoot, etc.). For those elements,
  # the :tag key will be ignored if it's set, so the tag can't be changed.
  mattr_reader :ui_elements
  @@ui_elements ||= {
    list: {tag: :div},
    list_header: {tag: :div},
    list_title: {tag: :h2},
    list_actions: {tag: :div},
    filters: {tag: :div, attributes: {class: 'filters'}},
    before_header_table: {tag: :table},
    list_content: {tag: :div},
    list_table: {}, # table
    list_messages: {attributes: {class: 'messages'}}, # tbody
    list_messages_container: {}, # td
    list_action_messages: {tag: :div},
    filtered_message: {tag: :div, attributes: {class: 'filtered-message'}},
    applied_filters_message: {tag: :div, attributes: {class: 'filtered-message applied-filters'}},
    empty_message: {tag: :p},
    message_reset: {tag: :div, attributes: {class: 'reset'}},
    message_close: {tag: :a, attributes: {href: '#', class: 'close'}},
    server_error: {tag: :p, attributes: {class: 'error-message message server-error'}},
    info_message: {tag: :div, attributes: {class: 'info-message message'}},
    warning_message: {tag: :div, attributes: {class: 'warning-message message'}},
    error_message: {tag: :div, attributes: {class: 'error-message message'}},
    list_footer: {tag: :div, attributes: {class: 'active-scaffold-footer'}},
    list_calculations: {}, # tr
    pagination_links: {tag: :div},
    record_actions_cell: {}, # td
    record_action_links: {}, # table
    action_link_group: {
      proc: lambda do |options|
        if options[:level]&.zero?
          tag = :div
          attributes = {class: 'action_group'}
        else
          tag = :li
          attributes = {class: ('top' if options[:first_action]).to_s}
        end
        attributes[:class] += ' hover_click' if hover_via_click?
        [tag, attributes]
      end
    },
    action_link_separator: {
      proc: lambda do |options|
        tag = options[:level_0_tag] || :a if options[:level]&.zero?
        [tag || :li, {class: 'separator'}]
      end
    },
    action_link_group_title: {tag: :div},
    action_link_group_content: {tag: :ul},
    search_form: {}, # form
    search_field: {attributes: {class: 'text-input', size: 50, autocomplete: :off}}, # input type=search
    search_submit: {attributes: {class: 'submit'}}, # input type=submit
    search_reset: {attributes: {class: 'reset'}}, # a
    field_search_form: {}, # form
    field_search_fields_container: {tag: :ol},
    field_search_subsection: {tag: :li, attributes: {class: 'sub-section'}},
    field_search_element: {tag: :li},
    field_search_submit: {attributes: {class: 'submit'}}, # input type=submit
    field_search_reset: {attributes: {class: 'reset'}}, # a
    form: {}, # form
    form_title: {tag: :h4},
    form_messages_container: {tag: :div},
    fields_container: {tag: :ol},
    form_subsection: {tag: :li, attributes: {class: 'sub-section'}},
    form_subsection_header: {tag: :h5},
    subform: {tag: :li},
    subform_record_remove: {}, # a
    subform_create_another: {}, # a
    subform_replace_with_new: {}, # a
    subform_add_existing: {}, # a
    form_element: {tag: :li},
    form_field_description: {tag: :span, attributes: {class: 'description'}},
    form_submit: {attributes: {class: 'submit'}}, # input type=submit
    form_apply: {attributes: {class: 'submit'}}, # input type=submit
    form_cancel: {} # a
  }

  def self.set_element_tag(name, tag)
    (ui_elements[name] ||= {})[:tag] = tag
  end

  def self.set_element_proc(name, &block)
    (ui_elements[name] ||= {})[:proc] = block
  end

  def self.add_element_attributes(name, attributes)
    attrs = (ui_elements[name] ||= {})[:attributes] || {}
    ui_elements[name][:attributes] = attrs.smart_merge(attributes)
  end

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
    "#{File.dirname(__FILE__)}/.."
  end

  def self.defaults(&)
    ActiveScaffold::Config::Core.configure(&)
  end

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('4.3', 'ActiveScaffold')
  end
end
require 'active_scaffold/engine'
require 'ice_nine'
require 'ice_nine/core_ext/object'
require 'request_store'
require 'dartsass-sprockets'
require 'html_attrs'
