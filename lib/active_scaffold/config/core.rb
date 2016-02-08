module ActiveScaffold::Config
  # to fix the ckeditor bridge problem inherit from full class name
  class Core < ActiveScaffold::Config::Base
    # global level configuration
    # --------------------------

    # provides read/write access to the global Actions DataStructure
    cattr_reader :actions
    def self.actions=(val)
      @@actions = ActiveScaffold::DataStructures::Actions.new(*val)
    end
    self.actions = [:create, :list, :search, :update, :delete, :show, :nested, :subform]

    # configures where the ActiveScaffold plugin itself is located. there is no instance version of this.
    cattr_accessor :plugin_directory
    @@plugin_directory = File.expand_path(__FILE__).match(%{(^.*)/lib/active_scaffold/config/core.rb})[1]

    # lets you specify a global ActiveScaffold frontend.
    cattr_accessor :frontend
    @@frontend = :default

    # lets you specify a global ActiveScaffold theme for your frontend.
    cattr_accessor :theme
    @@theme = :default

    # enable caching of action link urls
    cattr_accessor :cache_action_link_urls
    @@cache_action_link_urls = true

    # enable caching of association options
    cattr_accessor :cache_association_options
    @@cache_association_options = true

    # enable setting ETag and LastModified on responses and using fresh_when/stale? to respond with 304 and avoid rendering views
    cattr_accessor :conditional_get_support
    @@conditional_get_support = false

    # enable saving user settings in session (per_page, limit, page, sort, search params)
    cattr_accessor :store_user_settings
    @@store_user_settings = true

    # lets you disable the DHTML history
    def self.dhtml_history=(val)
      @@dhtml_history = val
    end
    def self.dhtml_history?
      @@dhtml_history ? true : false
    end
    @@dhtml_history = true

    # action links are used by actions to tie together. you can use them, too! this is a collection of ActiveScaffold::DataStructures::ActionLink objects.
    cattr_reader :action_links
    @@action_links = ActiveScaffold::DataStructures::ActionLinks.new

    # access to the permissions configuration.
    # configuration options include:
    #  * current_user_method - what method on the controller returns the current user. default: :current_user
    #  * default_permission - what the default permission is. default: true
    def self.security
      ActiveScaffold::ActiveRecordPermissions
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
    cattr_accessor :sti_create_links
    @@sti_create_links = true

    # prefix messages with current timestamp, set the format to display (you can use I18n keys) or true and :short will be used
    cattr_accessor :timestamped_messages
    @@timestamped_messages = false

    # a hash of string (or array of strings) and highlighter string to highlight words in messages. It will use highlight rails helper
    cattr_accessor :highlight_messages
    @@highlight_messages = nil

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
      @columns << val.collect { |c| c.to_sym unless @columns[c.to_sym] }.compact
    end

    # lets you override the global ActiveScaffold frontend for a specific controller
    attr_accessor :frontend

    # lets you override the global ActiveScaffold theme for a specific controller
    attr_accessor :theme

    # enable caching of action link urls
    attr_accessor :cache_action_link_urls

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
      as_(@label, options) || model.model_name.human(options.merge(options[:count].to_i == 1 ? {} : {:default => model.name.pluralize}))
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

    def initialize(model_id)
      # model_id is the only absolutely required configuration value. it is also not publicly accessible.
      @model_id = model_id

      # inherit the actions list directly from the global level
      @actions = self.class.actions.clone

      # create a new default columns datastructure, since it doesn't make sense before now
      attribute_names = model.columns.collect { |c| c.name.to_sym }.sort_by(&:to_s)
      association_column_names = model.reflect_on_all_associations.collect { |a| a.name.to_sym }.sort_by(&:to_s)
      @columns = ActiveScaffold::DataStructures::Columns.new(model, attribute_names + association_column_names)

      # and then, let's remove some columns from the inheritable set.
      content_columns = Set.new(model.content_columns.map(&:name))
      @columns.exclude(*self.class.ignore_columns)
      @columns.exclude(*@columns.find_all { |c| c.column && content_columns.exclude?(c.column.name) }.collect(&:name))
      @columns.exclude(*model.reflect_on_all_associations.collect { |a| a.foreign_type.to_sym if a.options[:polymorphic] }.compact)

      # inherit the global frontend
      @frontend = self.class.frontend
      @theme = self.class.theme
      @cache_action_link_urls = self.class.cache_action_link_urls
      @cache_association_options = self.class.cache_association_options
      @conditional_get_support = self.class.conditional_get_support
      @store_user_settings = self.class.store_user_settings
      @sti_create_links = self.class.sti_create_links

      # inherit from the global set of action links
      @action_links = self.class.action_links.clone
      @timestamped_messages = self.class.timestamped_messages
      @highlight_messages = self.class.highlight_messages
    end

    # To be called after your finished configuration
    def _load_action_columns
      # then, register the column objects
      actions.each do |action_name|
        action = send(action_name)
        action.columns.set_columns(columns) if action.respond_to?(:columns)
      end
    end

    # To be called after your finished configuration
    def _configure_sti
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

    # configuration routing.
    # we want to route calls named like an activated action to that action's global or local Config class.
    # ---------------------------
    def method_missing(name, *args)
      @action_configs ||= {}
      titled_name = name.to_s.camelcase
      underscored_name = name.to_s.underscore.to_sym
      klass = "ActiveScaffold::Config::#{titled_name}".constantize rescue nil
      if klass
        if @actions.include? underscored_name
          return @action_configs[underscored_name] ||= klass.new(self)
        else
          raise "#{titled_name} is not enabled. Please enable it or remove any references in your configuration (e.g. config.#{underscored_name}.columns = [...])."
        end
      end
      super
    end

    def self.method_missing(name, *args)
      klass = "ActiveScaffold::Config::#{name.to_s.camelcase}".constantize rescue nil
      return klass if @@actions.include?(name.to_s.underscore) && klass
      super
    end
    # some utility methods
    # --------------------

    attr_reader :model_id

    def model
      @model ||= @model_id.to_s.camelize.constantize
    end

    # warning - this won't work as a per-request dynamic attribute in rails 2.0.  You'll need to interact with Controller#generic_view_paths
    def inherited_view_paths
      @inherited_view_paths ||= []
    end

    # must be a class method so the layout doesn't depend on a controller that uses active_scaffold
    # note that this is unaffected by per-controller frontend configuration.
    def self.asset_path(filename, frontend = self.frontend)
      "active_scaffold/#{frontend}/#{filename}"
    end

    # must be a class method so the layout doesn't depend on a controller that uses active_scaffold
    # note that this is unaffected by per-controller frontend configuration.
    def self.javascripts(frontend = self.frontend)
      javascript_dir = File.join(Rails.public_path, 'javascripts', asset_path('', frontend))
      Dir.entries(javascript_dir).reject { |e| !e.match(/\.js$/) || (!self.dhtml_history? && e.match('dhtml_history')) }
    end

    def self.available_frontends
      frontends_dir = File.join(Rails.root, 'vendor', 'plugins', ActiveScaffold::Config::Core.plugin_directory, 'frontends')
      Dir.entries(frontends_dir).reject { |e| e.match(/^\./) } # Get rid of files that start with .
    end
  end
end
