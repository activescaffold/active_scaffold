# frozen_string_literal: true

module ActiveScaffold::Config
  # to fix the ckeditor bridge problem inherit from full class name
  class Core < ActiveScaffold::Config::Base
    include ActiveScaffold::OrmChecks

    # global level configuration
    # --------------------------

    # provides read/write access to the global Actions DataStructure
    cattr_reader :actions, instance_accessor: false
    def self.actions=(val)
      @@actions = ActiveScaffold::DataStructures::Actions.new(*val)
    end
    self.actions = %i[create list search update delete show nested subform]

    # configures where the ActiveScaffold plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory
    @@plugin_directory = File.expand_path(__FILE__).match(%{(^.*)/lib/active_scaffold/config/core.rb})[1]

    # lets you specify a global ActiveScaffold theme for your frontend.
    cattr_accessor :theme, instance_accessor: false
    @@theme = :default

    # enable caching of action link urls
    cattr_accessor :cache_action_link_urls, instance_accessor: false
    @@cache_action_link_urls = true

    # enable caching of action links
    cattr_accessor :cache_action_links, instance_accessor: false
    @@cache_action_links = true

    # enable caching of association options
    cattr_accessor :cache_association_options, instance_accessor: false
    @@cache_association_options = true

    # enable setting ETag and LastModified on responses and using fresh_when/stale? to respond with 304 and avoid rendering views
    cattr_accessor :conditional_get_support, instance_accessor: false
    @@conditional_get_support = false

    # enable saving user settings in session (per_page, limit, page, sort, search params)
    cattr_accessor :store_user_settings, instance_accessor: false
    @@store_user_settings = true

    # action links are used by actions to tie together. you can use them, too! this is a collection of ActiveScaffold::DataStructures::ActionLink objects.
    cattr_reader :action_links, instance_reader: false
    @@action_links = ActiveScaffold::DataStructures::ActionLinks.new

    # modules to include after all ActiveScaffold modules are included, to include generic customizations in all controllers
    cattr_reader :custom_modules, instance_reader: false
    @@custom_modules = []

    # access to the permissions configuration.
    # configuration options include:
    #  * current_user_method - what method on the controller returns the current user. default: :current_user
    #  * default_permission - what the default permission is. default: true
    def self.security
      ActiveScaffold::ActiveRecordPermissions
    end

    # access to default column configuration.
    def self.column
      ActiveScaffold::DataStructures::Column
    end

    # columns that should be ignored for every model. these should be metadata columns like change dates, versions, etc.
    # values in this array may be symbols or strings.
    def self.ignore_columns
      @@ignore_columns
    end

    def self.ignore_columns=(val)
      @@ignore_columns = ActiveScaffold::DataStructures::Set.new(*val)
    end
    @@ignore_columns = ActiveScaffold::DataStructures::Set.new

    # lets you specify whether add a create link for each sti child
    cattr_accessor :sti_create_links, instance_accessor: false
    @@sti_create_links = true

    # prefix messages with current timestamp, set the format to display (you can use I18n keys) or true and :short will be used
    cattr_accessor :timestamped_messages, instance_accessor: false
    @@timestamped_messages = false

    # a hash of string (or array of strings) and highlighter string to highlight words in messages. It will use highlight rails helper
    cattr_accessor :highlight_messages, instance_accessor: false
    @@highlight_messages = nil

    # method names or procs to be called after all configure blocks
    cattr_reader :after_config_callbacks, instance_accessor: false
    @@after_config_callbacks = [:_configure_sti]

    def self.freeze
      super
      security.freeze
      column.freeze
    end

    # instance-level configuration
    # ----------------------------

    # provides read/write access to the local Actions DataStructure
    attr_reader :actions

    def actions=(args)
      @actions = ActiveScaffold::DataStructures::Actions.new(*args)
    end

    # provides read/write access to the local Columns DataStructure
    attr_reader :columns

    def columns=(val)
      @columns._inheritable = val.collect(&:to_sym)
      # Add virtual columns
      @columns.add(*val)
    end

    # lets you override the global ActiveScaffold theme for a specific controller
    attr_accessor :theme

    # modules to include after all ActiveScaffold modules are included, to include generic customizations in some controllers
    # These modules are included after the modules in global custom_modules setting.
    attr_reader :custom_modules

    # enable caching of action link urls
    attr_accessor :cache_action_link_urls

    # enable caching of action links
    attr_accessor :cache_action_links

    # enable caching of association options
    attr_accessor :cache_association_options

    # enable setting ETag and LastModified on responses and using fresh_when/stale? to respond with 304 and avoid rendering views
    attr_accessor :conditional_get_support

    # enable saving user settings in session (per_page, limit, page, sort, search params)
    attr_accessor :store_user_settings

    # lets you specify whether add a create link for each sti child for a specific controller
    attr_accessor :sti_create_links

    def add_sti_create_links?
      sti_create_links && !sti_children.nil?
    end

    # action links are used by actions to tie together. they appear as links for each record, or general links for the ActiveScaffold.
    attr_reader :action_links

    # a generally-applicable name for this ActiveScaffold ... will be used for generating page/section headers
    attr_writer :label

    def label(options = {})
      as_(@label, options) || model.model_name.human(options.merge(options[:count].to_i == 1 ? {} : {default: model.name.pluralize}))
    end

    # STI children models, use an array of model names
    attr_accessor :sti_children

    # prefix messages with current timestamp, set the format to display (you can use I18n keys) or true and :short will be used
    attr_accessor :timestamped_messages

    # a hash of string (or array of strings) and highlighter string to highlight words in messages. It will use highlight rails helper
    attr_accessor :highlight_messages

    ##
    ## internal usage only below this point
    ## ------------------------------------

    def initialize(model_id) # rubocop:disable Lint/MissingSuper
      # model_id is the only absolutely required configuration value. it is also not publicly accessible.
      @model_id = model_id
      @custom_modules = []
      setup_user_setting_key

      # inherit the actions list directly from the global level
      @actions = self.class.actions.clone

      # create a new default columns datastructure, since it doesn't make sense before now
      attribute_names = _columns.collect { |c| c.name.to_sym }.sort_by(&:to_s)
      association_column_names = _reflect_on_all_associations.collect { |a| a.name.to_sym }
      if defined?(ActiveMongoid) && model < ActiveMongoid::Associations
        association_column_names.concat model.am_relations.keys.map(&:to_sym)
      end
      @columns = ActiveScaffold::DataStructures::Columns.new(model, attribute_names + association_column_names.sort_by(&:to_s))

      # and then, let's remove some columns from the inheritable set.
      content_columns = Set.new(_content_columns.map(&:name))
      @columns.exclude(*self.class.ignore_columns)
      @columns.exclude(*@columns.find_all { |c| c.column && content_columns.exclude?(c.column.name) }.collect(&:name))
      @columns.exclude(*model.reflect_on_all_associations.filter_map { |a| a.foreign_type.to_sym if a.options[:polymorphic] })

      @theme = self.class.theme
      @cache_action_link_urls = self.class.cache_action_link_urls
      @cache_action_links = self.class.cache_action_links
      @cache_association_options = self.class.cache_association_options
      @conditional_get_support = self.class.conditional_get_support
      @store_user_settings = self.class.store_user_settings
      @sti_create_links = self.class.sti_create_links

      # inherit from the global set of action links
      @action_links = self.class.action_links.clone
      @timestamped_messages = self.class.timestamped_messages
      @highlight_messages = self.class.highlight_messages
    end

    # To be called before freezing
    def _cache_lazy_values
      action_links.collection # ensure the collection group exist although it's empty
      action_links.member # ensure the collection group exist although it's empty
      if cache_action_link_urls || cache_action_links
        action_links.each(&:name_to_cache)
        list.filters.each { |filter| filter.each(&:name_to_cache) } if actions.include?(:list)
      end
      columns.select(&:sortable?).each(&:sort)
      columns.select(&:searchable?).each(&:search_sql)
      columns.each(&:field)
      actions.each do |action_name|
        action = send(action_name)
        Array(action.class.columns_collections).each { |method| action.send(method) }
      end
    end

    # To be called after your finished configuration
    def _configure_sti
      return if sti_children.nil?

      column = model.inheritance_column
      if sti_create_links
        columns[column].form_ui ||= :hidden
      else
        columns[column].form_ui ||= :select
        columns[column].options ||= {}
        columns[column].options[:options] = sti_children.collect do |model_name|
          [model_name.to_s.camelize.constantize.model_name.human, model_name.to_s.camelize]
        end
      end
    end

    def _setup_action(action)
      define_singleton_method action do
        self[action]
      end
    end

    # configuration routing.
    # we want to route calls named like an activated action to that action's global or local Config class.
    # ---------------------------
    def method_missing(name, *args)
      self[name] || super
    end

    def respond_to_missing?(name, include_all = false)
      (self.class.config_class?(name) && @actions.include?(name.to_sym)) || super
    end

    def [](action_name)
      klass = self.class.config_class(action_name)
      return unless klass

      underscored_name = action_name.to_s.underscore.to_sym
      unless @actions.include? underscored_name
        raise ArgumentError, "#{action_name.to_s.camelcase} is not enabled. Please enable it or remove any references in your configuration (e.g. config.#{underscored_name}.columns = [...])."
      end

      @action_configs ||= {}
      @action_configs[underscored_name] ||= klass.new(self)
    end

    def []=(action_name, action_config)
      @action_configs ||= {}
      @action_configs[action_name] = action_config
    end
    private :[]=

    def self.method_missing(name, *args)
      config_class(name) || super
    end

    def self.config_class(name)
      "ActiveScaffold::Config::#{name.to_s.camelcase}".constantize if config_class?(name)
    end

    def self.config_class?(name)
      ActiveScaffold::Config.const_defined? name.to_s.camelcase
    end

    def self.respond_to_missing?(name, include_all = false)
      (config_class?(name) && @@actions.include?(name.to_s.underscore)) || super
    end
    # some utility methods
    # --------------------

    attr_reader :model_id

    def model
      @model ||= @model_id.to_s.camelize.constantize
    end
    alias active_record_class model

    def primary_key
      mongoid? ? '_id' : model.primary_key
    end

    # warning - this won't work as a per-request dynamic attribute in rails 2.0.  You'll need to interact with Controller#generic_view_paths
    def inherited_view_paths
      @inherited_view_paths ||= []
    end

    def build_action_columns(action, columns)
      action_columns =
        if columns.is_a?(ActiveScaffold::DataStructures::ActionColumns)
          columns.dup
        else
          ActiveScaffold::DataStructures::ActionColumns.new(*columns)
        end
      action_columns.action = action.is_a?(Symbol) ? send(action) : action
      action_columns
    end

    class UserSettings < Base::UserSettings
      include ActiveScaffold::Configurable

      user_attr :cache_action_link_urls, :cache_action_links, :cache_association_options,
                :conditional_get_support, :timestamped_messages, :highlight_messages
      attr_writer :label

      def label(options = {})
        @label ? as_(@label, options) : @conf.label(options)
      end

      def method_missing(name, *args)
        value = @conf.actions.include?(name) ? @conf.send(name) : super
        value.is_a?(Base) ? action_user_settings(value) : value
      end

      def respond_to_missing?(name, include_all = false)
        super # avoid rubocop warning
      end

      def action_user_settings(action_config)
        if action_config.user.nil? && action_config.respond_to?(:new_user_settings)
          action_config.new_user_settings @storage, @params
        end
        action_config.user || action_config
      end

      def columns
        @columns ||= UserColumns.new(@conf.columns)
      end

      delegate :action_links, :model, :actions, to: :@conf
    end

    class UserColumns
      include Enumerable

      def initialize(columns)
        @global_columns = columns
        @columns = {}
      end

      def [](name)
        @columns[name.to_sym] || @global_columns[name]
      end

      def override(name)
        raise ArgumentError, "column '#{name}' doesn't exist" unless @global_columns[name]

        (@columns[name.to_sym] ||= ActiveScaffold::DataStructures::ProxyColumn.new(@global_columns[name])).tap do |col|
          yield col if block_given?
        end
      end

      def each
        return enum_for(:each) unless block_given?

        @global_columns.each do |col|
          yield self[col.name]
        end
      end

      def method_missing(name, ...)
        if respond_to_missing?(name, true)
          @global_columns.send(name, ...)
        else
          super
        end
      end

      DONT_DELEGATE = %i[add exclude add_association_columns _inheritable=].freeze
      def respond_to_missing?(name, include_all = false)
        (DONT_DELEGATE.exclude?(name) && @global_columns.respond_to?(name, include_all)) || super
      end
    end
  end
end
