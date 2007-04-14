module ActiveScaffold::Config
  class Core < Base
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
    @@plugin_directory = File.expand_path(__FILE__).match(/vendor\/plugins\/(\w*)/)[1]

    # lets you specify a global ActiveScaffold frontend.
    cattr_accessor :frontend
    @@frontend = :default

    # lets you specify a global ActiveScaffold theme for your frontend.
    cattr_accessor :theme
    @@theme = :default

    # action links are used by actions to tie together. you can use them, too! this is a collection of ActiveScaffold::DataStructures::ActionLink objects.
    cattr_reader :action_links
    @@action_links = ActiveScaffold::DataStructures::ActionLinks.new

    # access to the permissions configuration.
    # configuration options include:
    #  * current_user_method - what method on the controller returns the current user. default: :current_user
    #  * default_permission - what the default permission is. default: true
    def self.security
      ActiveRecordPermissions
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
      @columns = ActiveScaffold::DataStructures::Columns.new(self.model, *val)
    end

    # lets you override the global ActiveScaffold frontend for a specific controller
    attr_accessor :frontend

    # lets you override the global ActiveScaffold theme for a specific controller
    attr_accessor :theme

    # action links are used by actions to tie together. they appear as links for each record, or general links for the ActiveScaffold.
    attr_reader :action_links

    # a generally-applicable name for this ActiveScaffold ... will be used for generating page/section headers
    attr_writer :label
    def label
      as_(@label)
    end

    ##
    ## internal usage only below this point
    ## ------------------------------------

    def initialize(model_id)
      # model_id is the only absolutely required configuration value. it is also not publicly accessible.
      @model_id = model_id.to_s.pluralize.singularize

      # inherit the actions list directly from the global level
      @actions = self.class.actions.clone

      # create a new default columns datastructure, since it doesn't make sense before now
      content_column_names = self.model.content_columns.collect{ |c| c.name.to_sym }.sort_by { |c| c.to_s }
      association_column_names = self.model.reflect_on_all_associations.collect{ |a| a.name.to_sym }.sort_by { |c| c.to_s }
      column_names = content_column_names + association_column_names
      column_names -= self.class.ignore_columns.collect { |c| c.to_sym }
      column_names -= self.model.reflect_on_all_associations.collect{|a| "#{a.name}_type".to_sym if a.options[:polymorphic]}.compact
      self.columns = column_names

      # inherit the global frontend
      @frontend = self.class.frontend
      @theme = self.class.theme

      # inherit from the global set of action links
      @action_links = self.class.action_links.clone

      # the default label
      @label = self.model_id.pluralize.titleize
    end

    # To be called after your finished configuration
    def _load_action_columns
      ActiveScaffold::DataStructures::ActionColumns.class_eval {include ActiveScaffold::DataStructures::ActionColumns::AfterConfiguration}

      # then, register the column objects
      self.actions.each do |action_name|
        action = self.send(action_name)
        next unless action.respond_to? :columns
        action.columns.set_columns(self.columns)
      end
    end

    # configuration routing.
    # we want to route calls named like an activated action to that action's global or local Config class.
    # ---------------------------
    def method_missing(name, *args)
      @action_configs ||= {}
      titled_name = name.to_s.camelcase
      underscored_name = name.to_s.underscore.to_sym
      if ActiveScaffold::Config.const_defined? titled_name
        if @actions.include? underscored_name
          return @action_configs[underscored_name] ||= eval("ActiveScaffold::Config::#{titled_name}").new(self)
        else
          raise "#{titled_name} is not enabled. Please enable it or remove any references in your configuration (e.g. config.#{underscored_name}.columns = [...])."
        end
      end
      super
    end

    def self.method_missing(name, *args)
      if @@actions.include? name.to_s.underscore and ActiveScaffold::Config.const_defined? name.to_s.titleize
        return eval("ActiveScaffold::Config::#{name.to_s.titleize}")
      end
      super
    end

    # some utility methods
    # --------------------

    def model_id
      @model_id
    end

    def model
      @model ||= @model_id.to_s.camelize.constantize
    end

    def self.asset_path(type, filename)
      "active_scaffold/#{ActiveScaffold::Config::Core.frontend.to_s}/#{filename}"
    end

    def self.javascripts
      javascript_dir = File.join(RAILS_ROOT, "vendor", "plugins", ActiveScaffold::Config::Core.plugin_directory, "frontends", ActiveScaffold::Config::Core.frontend.to_s, "javascripts")
      Dir.entries(javascript_dir).reject { |e| !e.match(/\.js/) }
    end

    # the ActiveScaffold-specific template paths
    def self.template_search_path
      search_path = []
      search_path << 'active_scaffold_overrides'
      search_path <<  "../../vendor/plugins/#{ActiveScaffold::Config::Core.plugin_directory}/frontends/#{ActiveScaffold::Config::Core.frontend.to_s}/views" if ActiveScaffold::Config::Core.frontend.to_sym != :default
      search_path << "../../vendor/plugins/#{ActiveScaffold::Config::Core.plugin_directory}/frontends/default/views"
      return search_path
    end

    def self.available_frontends
      frontends_dir = File.join(RAILS_ROOT, "vendor", "plugins", ActiveScaffold::Config::Core.plugin_directory, "frontends")
      Dir.entries(frontends_dir).reject { |e| e.match(/^\./) } # Get rid of files that start with .
    end
  end
end
