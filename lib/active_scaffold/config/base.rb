module ActiveScaffold::Config
  class Base
    include ActiveScaffold::Configurable
    extend ActiveScaffold::Configurable
    NO_FORMATS = [].freeze

    def initialize(core_config)
      @core = core_config
      @action_group = self.class.action_group.clone if self.class.action_group

      # start with the ActionLink defined globally
      @link = self.class.link.clone if self.class.respond_to?(:link) && self.class.link
    end
    attr_reader :core

    def self.inherited(subclass)
      class << subclass
        # the crud type of the action. possible values are :create, :read, :update, :delete, and nil.
        # this is not a setting for the developer. it's self-description for the actions.
        attr_reader :crud_type

        protected

        def crud_type=(val)
          raise ArgumentError, "unknown CRUD type #{val}" unless [:create, :read, :update, :delete].include?(val.to_sym)
          @crud_type = val.to_sym
        end
      end
    end

    # delegate
    def crud_type
      self.class.crud_type
    end

    def label(model = nil)
      model ||= @core.label(:count => 1)
      @label.nil? ? model : as_(@label, :model => model)
    end

    def model_id
      (core || self).model_id
    end

    # the user property gets set to the instantiation of the local UserSettings class during the automatic instantiation of this class.
    def user
      Thread.current["#{model_id}_#{self.class.name.underscore}_user"]
    end

    def new_user_settings(conf_instance, storage, params)
      Thread.current["#{model_id}_#{self.class.name.underscore}_user"] = self.class::UserSettings.new(conf_instance, storage, params)
    end

    # define a default action_group for this action
    # e.g. 'members.crud'
    class_attribute :action_group, instance_accessor: false

    # action_group this action should belong to
    attr_accessor :action_group

    class UserSettings
      # define setter and getter for names
      # values will be saved for current request only
      # getter will return value set with setter, or value from conf
      def self.user_attr(*names)
        attr_writer *names
        names.each do |name|
          define_method(name) { instance_variable_get("@#{name}") || @conf.send(name) }
        end
      end

      # define setter and getter for names
      # values will be saved in session if store_user_settings is enabled,
      # in other case for current request only
      # getter will return value set with setter, or value from conf
      def self.session_attr(*names)
        names.each do |name|
          define_method(name) { |value| self[name] = value }
          define_method(name) { self[name] || @conf.send(name) }
        end
      end

      def initialize(conf, storage, params, action = :base)
        # the session hash relevant to this action
        @storage = storage
        # all the request params
        @params = params
        # the configuration object for this action
        @conf = conf
        @action = action.to_s
      end

      def [](key)
        @storage[@action][key.to_s] if @action && @storage[@action]
      end

      def []=(key, value)
        @storage[@action] ||= {}
        if value
          @storage[@action][key.to_s] = value
        else
          @storage[@action].delete key.to_s
          @storage.delete @action if @storage[@action].empty?
        end
      end
    end

    def formats
      return @formats || NO_FORMATS if frozen?
      @formats ||= NO_FORMATS.dup
    end
    attr_writer :formats

    private

    def build_action_columns(val)
      columns =
        if val.is_a?(ActiveScaffold::DataStructures::ActionColumns)
          val.dup
        else
          ActiveScaffold::DataStructures::ActionColumns.new(*val)
        end
      columns.action = self
      columns.set_columns(@core.columns)
      columns
    end

    def self.columns_accessor(*names, &block)
      options = names.extract_options!
      names.each do |name|
        var = "@#{name}"
        define_method "#{name}=" do |val|
          if instance_variable_defined?(var)
            instance_variable_get(var).set_values(*val)
          else
            instance_variable_set(var, build_action_columns(val))
          end
          instance_variable_get(var)
        end

        return if method_defined? name
        define_method name do
          unless instance_variable_defined?(var) # lazy evaluation
            action, columns = options[:copy] if options[:copy]
            if action && @core.actions.include?(action)
              action_columns = @core.send(action).send(columns || :columns).clone
              action_columns.action = self
              instance_variable_set(var, action_columns)
            else
              send("#{name}=", @core.columns._inheritable)
            end
            instance_exec(&block) if block
          end
          instance_variable_get(var)
        end
      end
    end

    private_class_method :columns_accessor
  end
end
