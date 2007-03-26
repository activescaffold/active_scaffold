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

    # action links are used by actions to tie together. you can use them, too! this is a collection of ActiveScaffold::DataStructures::ActionLink objects.
    cattr_reader :action_links
    @@action_links = ActiveScaffold::DataStructures::ActionLinks.new

    # the name of a method that will return the current user. this will be used for security checks against records.
    cattr_accessor :current_user_method
    @@current_user_method = :current_user

    # columns that should be ignored for every model. these should be metadata columns like change dates, versions, etc.
    # values in this array may be symbols or strings.
    cattr_accessor :ignore_columns
    def ignore_columns=(val)
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

    # action links are used by actions to tie together. they appear as links for each record, or general links for the ActiveScaffold.
    attr_reader :action_links

    # a generally-applicable name for this ActiveScaffold ... will be used for generating page/section headers
    attr_accessor :label
    def label
      _(@label)
    end

    # the name of a method that will return the current user. this will be used for security checks against records.
    attr_accessor :current_user_method

    ##
    ## internal usage only below this point
    ## ------------------------------------

    def initialize(model_id)
      # model_id is the only absolutely required configuration value. it is also not publicly accessible.
      @model_id = model_id.to_s.pluralize.singularize

      # inherit the actions list directly from the global level
      @actions = self.class.actions.clone

      # create a new default columns datastructure, since it doesn't make sense before now
      content_column_names = self.model.content_columns.collect { |c| c.name.to_sym }
      association_column_names = self.model.reflect_on_all_associations.collect { |a| a.name.to_sym }
      column_names = content_column_names + association_column_names
      column_names -= self.class.ignore_columns.collect { |c| c.to_sym }
      self.columns = column_names

      # inherit the global frontend
      @frontend = self.class.frontend

      # inherit from the global set of action links
      @action_links = self.class.action_links.clone

      # the default label
      @label = self.model_id.pluralize.titleize

      @current_user_method = self.class.current_user_method
    end

    # To be called after your finished configuration
    def _load_action_columns
      # add enumerability to the ActionColumns objects. we don't want to do this earlier because right now we don't want the ActionColumns object to have any access during the configuration to actual Column objects. basically we just don't want someone trying to use the iterator in an unsupported way and then complaining because things are broken.
      # first, add an iterator that returns actual Column objects and a method for registering Column objects
      ActiveScaffold::DataStructures::ActionColumns.class_eval do
        include Enumerable
        def each(options = {}, &proc)
          @set.each do |item|
            unless item.is_a? ActiveScaffold::DataStructures::ActionColumns
              begin
                item = (@columns[item] || ActiveScaffold::DataStructures::Column.new(item.to_sym, @columns.active_record_class))
                next if constraint_columns.include?(item.name.to_sym) or (item.field_name and constraint_columns.include?(item.field_name.to_sym))
              rescue ActiveScaffold::ColumnNotAllowed
                next
              end
            end
            if item.is_a? ActiveScaffold::DataStructures::ActionColumns and options.has_key?(:flatten) and options[:flatten]
              item.each(options, &proc)
            else
              yield item
            end
          end
        end

        # registers a set of column objects (recursively, for all nested ActionColumns)
        def set_columns(columns)
          @columns = columns
          self.each do |item|
            item.set_columns(columns) if item.respond_to? :set_columns
          end
        end

        attr_writer :constraint_columns
        def constraint_columns
          @constraint_columns ||= []
        end
      end
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
      name = name.to_s
      if @@actions.include? name.underscore and ActiveScaffold::Config.const_defined? name.titleize
        return eval("ActiveScaffold::Config::#{name.titleize}")
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
